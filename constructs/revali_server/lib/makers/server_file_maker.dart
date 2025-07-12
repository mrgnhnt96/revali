// ignore_for_file: unnecessary_parenthesis

import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide AllowOrigins, Method;
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/creators/create_app.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/creators/create_dependency_injection.dart';
import 'package:revali_server/makers/creators/create_mimic.dart';
import 'package:revali_server/makers/creators/create_modifier_args.dart';
import 'package:revali_server/makers/creators/create_routes_variable.dart';
import 'package:revali_server/makers/utils/try_catch.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/models/options.dart';

String serverFile(
  ServerServer server,
  String Function(Spec) formatter, {
  required Options options,
}) {
  final imports = [
    if (options.ignoreLints case final lints when lints.isNotEmpty)
      "// ignore_for_file: ${options.ignoreLints.join(', ')}\n",
    "import 'dart:io';",
    "import 'dart:async';",
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
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'args'
            ..type = refer('List<String>'),
        ),
      )
      ..body = Block.of([
        if (server.context.mode.isDebug)
          refer('hotReload').call([
            Method(
              (b) => b
                ..lambda = true
                ..body = refer('createServer')
                    .call([literalNull, refer('args')]).code,
            ).closure,
          ]).statement
        else
          refer('createServer').call([literalNull, refer('args')]).statement,
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
      ..optionalParameters.addAll([
        Parameter(
          (e) => e
            ..name = 'providedServer'
            ..named = false
            ..type = refer('${(HttpServer).name}?'),
        ),
        Parameter(
          (e) => e
            ..name = 'rawArgs'
            ..named = false
            ..defaultTo = const Code('const []')
            ..type = refer('List<String>'),
        ),
      ])
      ..body = Block.of([
        declareFinal('args')
            .assign(
              refer((Args).name).newInstanceNamed('parse', [refer('rawArgs')]),
            )
            .statement,
        declareFinal('app', type: refer((AppConfig).name))
            .assign(createApp(app))
            .statement,
        declareFinal('server', late: true, type: refer('HttpServer')).statement,
        tryCatch(
          refer('server')
              .assign(
                refer('providedServer').ifNullThen(
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
                ),
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
                  if (app.observers.hasObservers)
                    'observers': literalList([
                      if (app.observers.types.expand((e) => e.types)
                          case final observers when observers.isNotEmpty)
                        for (final observer in observers) createClass(observer),
                      if (app.observers.mimics case final mimics
                          when mimics.isNotEmpty)
                        for (final type in mimics) createMimic(type),
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
                refer('router').property('responseHandler'),
                refer('router').property('close'),
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
