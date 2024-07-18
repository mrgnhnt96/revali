import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method, AllowOrigins;
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/creators/create_app.dart';
import 'package:revali_server/makers/creators/create_modifier_args.dart';
import 'package:revali_server/makers/utils/try_catch.dart';

String serverFile(ServerServer server, String Function(Spec) formatter) {
  final imports = [
    "import 'dart:io';",
    '',
    "import 'package:path/path.dart' as p;",
    for (final imprt in {
      if (server.context.mode.isDebug)
        'package:revali_construct/revali_construct.dart',
      'package:revali_router/revali_router.dart',
      ...server.packageImports(),
    })
      "import '$imprt';",
    '',
    for (final imprt in {...server.pathImports()}) "import '../$imprt';",
  ];

  final app = server.app;
  if (app == null) {
    throw Exception('No app found');
  }

  final main = Method(
    (b) => b
      ..name = 'main'
      ..returns = refer('void')
      ..body = Block.of([
        if (server.context.mode.isDebug)
          refer('hotReload').call([refer('createServer')]).statement
        else
          refer('createServer').call([]).statement,
      ]),
  );

  final createServer = Method(
    (b) => b
      ..name = 'createServer'
      ..returns = TypeReference(
        (p) => p
          ..symbol = 'Future'
          ..types.add(
            refer('HttpServer'),
          ),
      )
      ..modifier = MethodModifier.async
      ..body = Block.of([
        declareFinal('app').assign(createApp(app)).statement,
        declareFinal('server', late: true, type: refer('HttpServer')).statement,
        tryCatch(
          refer('server')
              .assign(refer('HttpServer')
                  .property(app.isSecure ? 'bindSecure' : 'bind')
                  .call([
                refer('app').property('host'),
                refer('app').property('port'),
                if (app.isSecure)
                  refer('app').property('securityContext').nullChecked,
              ], {
                if (app.isSecure)
                  'requestClientCertificate':
                      refer('app').property('requestClientCertificate'),
                if (server.context.mode.isDebug) 'shared': literalTrue,
              }).awaited)
              .statement,
          Block.of([
            refer('print').call(
                [literalString('Failed to bind server:\\n\$e')]).statement,
            refer('exit').call([literalNum(1)]).statement,
          ]),
        ),
        Code('\n'),
        declareFinal('di').assign(refer('$DIImpl').newInstance([])).statement,
        refer('app')
            .property('configureDependencies')
            .call([refer('di')])
            .awaited
            .statement,
        refer('di').property('finishRegistration').call([]).statement,
        Code('\n'),
        declareVar('_routes')
            .assign(refer('routes').call([refer('di')]))
            .statement,
        Block.of([
          Code('if ('),
          refer('app').property('prefix').code,
          Code(' case'),
          declareFinal('prefix?').code,
          Code(' when '),
          refer('prefix').property('isNotEmpty').code,
          Code(') {'),
          refer('_routes')
              .assign(literalList([
                refer('$Route').newInstance([
                  refer('prefix')
                ], {
                  'routes': refer('_routes'),
                }),
              ]))
              .statement,
          Code('}'),
        ]),
        Code('\n'),
        declareFinal('router')
            .assign(refer('$Router').newInstance(
              [],
              {
                'routes': literalList([
                  refer('_routes').spread,
                  refer('public').spread,
                ]),
                'reflects': refer('reflects'),
                if (server.app case final app?
                    when app.globalRouteAnnotations.hasAnnotations)
                  'globalModifiers':
                      refer('$RouteModifiersImpl').newInstance([], {
                    ...createModifierArgs(
                      annotations: app.globalRouteAnnotations,
                    )
                  })
              },
            ))
            .statement,
        Code('\n'),
        refer('handleRequests').call(
          [
            refer('server'),
            refer('router').property('handle'),
          ],
        ).statement,
        Code('\n'),
        refer('app').property('onServerStarted').call(
          [refer('server')],
        ).statement,
        Code('\n'),
        refer('server').returned.statement,
      ]),
  );

  final parts = <Spec>[
    main,
    createServer,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}
