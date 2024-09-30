// ignore_for_file: unnecessary_parenthesis

import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide AllowOrigins, Method;
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
    for (final imprt in {...server.pathImports()}) "import '../../$imprt';",
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
              .assign(
                refer((HttpServer).name)
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
                }).awaited,
              )
              .statement,
          Block.of([
            refer('print').call(
              [literalString(r'Failed to bind server:\n$e')],
            ).statement,
            refer('exit').call([literalNum(1)]).statement,
          ]),
        ),
        const Code('\n'),
        declareFinal('di')
            .assign(refer((DIImpl).name).newInstance([]))
            .statement,
        ...createDependencyInjection(server),
        const Code('\n'),
        ...createRoutesVariable(server),
        const Code('\n'),
        Block.of([
          const Code('if ('),
          refer('app').property('prefix').code,
          const Code(' case'),
          declareFinal('prefix?').code,
          const Code(' when '),
          refer('prefix').property('isNotEmpty').code,
          const Code(') {'),
          refer('_routes')
              .assign(
                literalList([
                  refer((Route).name).newInstance([
                    refer('prefix'),
                  ], {
                    'routes': refer('_routes'),
                  }),
                ]),
              )
              .statement,
          const Code('}'),
        ]),
        const Code('\n'),
        declareFinal('router')
            .assign(
              refer((Router).name).newInstance(
                [],
                {
                  if (server.context.mode.isNotRelease) 'debug': literalTrue,
                  'routes': literalList([
                    refer('_routes').spread,
                    refer('public').spread,
                  ]),
                  if (app.observers.isNotEmpty)
                    'observers': literalConstList([
                      for (final observer in app.observers)
                        createMimic(observer),
                    ]),
                  'reflects': refer('reflects'),
                  'defaultResponses': refer('app').property('defaultResponses'),
                  if (server.app case final app?
                      when app.globalRouteAnnotations.hasAnnotations)
                    'globalComponents':
                        refer((LifecycleComponentsImpl).name).newInstance([], {
                      ...createModifierArgs(
                        annotations: app.globalRouteAnnotations,
                      ),
                    }),
                },
              ),
            )
            .statement,
        const Code('\n'),
        refer('handleRequests')
            .call(
              [
                refer('server'),
                refer('router').property('handle'),
              ],
            )
            .property('ignore')
            .call([])
            .statement,
        const Code('\n'),
        refer('app').property('onServerStarted').call(
          [refer('server')],
        ).statement,
        const Code('\n'),
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
