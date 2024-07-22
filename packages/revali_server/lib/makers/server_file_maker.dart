import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method, AllowOrigins;
import 'package:revali_server/makers/creators/create_dependency_injection.dart';
import 'package:revali_server/makers/creators/create_routes_variable.dart';
import 'package:revali_server/models/options.dart';
import 'package:revali_server/revali_server.dart';

String serverFile(
  ServerServer server,
  String Function(Spec) formatter, {
  required Options options,
}) {
  final imports = [
    if (options.ignoreLints case final lints when lints.isNotEmpty)
      "// ignore_for_file: ${options.ignoreLints.join(', ')}\n",
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
          ..symbol = (Future).name
          ..types.add(
            refer((HttpServer).name),
          ),
      )
      ..modifier = MethodModifier.async
      ..body = Block.of([
        declareFinal('app').assign(createApp(app)).statement,
        declareFinal('server', late: true, type: refer('HttpServer')).statement,
        tryCatch(
          refer('server')
              .assign(refer((HttpServer).name)
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
        declareFinal('di')
            .assign(refer((DIImpl).name).newInstance([]))
            .statement,
        ...createDependencyInjection(server),
        Code('\n'),
        ...createRoutesVariable(server),
        Code('\n'),
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
                refer((Route).name).newInstance([
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
            .assign(refer((Router).name).newInstance(
              [],
              {
                if (server.context.mode.isDebug) 'debug': literalTrue,
                'routes': literalList([
                  refer('_routes').spread,
                  refer('public').spread,
                ]),
                if (app.observers.isNotEmpty)
                  'observers': literalList([
                    for (final observer in app.observers) createMimic(observer)
                  ]),
                'reflects': refer('reflects'),
                if (server.app case final app?
                    when app.globalRouteAnnotations.hasAnnotations)
                  'globalModifiers':
                      refer((RouteModifiersImpl).name).newInstance([], {
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
