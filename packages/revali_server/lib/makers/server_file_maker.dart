import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/parts/create_app.dart';
import 'package:revali_server/makers/parts/create_modifier_args.dart';
import 'package:revali_server/makers/parts/create_parent_ref.dart';
import 'package:revali_server/makers/parts/create_reflect.dart';
import 'package:revali_server/makers/utils/try_catch.dart';

String serverFile(ServerServer server, String Function(Spec) formatter) {
  final imports = [
    "import 'dart:io';",
    '',
    "import 'package:path/path.dart' as p;",
    "import 'package:revali_construct/revali_construct.dart';",
    "import 'package:revali_router_annotations/revali_router_annotations.dart';",
    "import 'package:revali_router_core/revali_router_core.dart';",
    "import 'package:revali_router/revali_router.dart';",
    '',
    for (final imprt in {...server.packageImports()}) "import '$imprt';",
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
        refer('hotReload').call([refer('createServer')]).statement,
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
                'shared': literalTrue,
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

  final routes = Method((p) => p
    ..name = 'routes'
    ..lambda = true
    ..requiredParameters.add(
      Parameter((p) => p
        ..name = 'di'
        ..type = refer('$DI')),
    )
    ..returns = TypeReference(
      (b) => b
        ..symbol = 'List'
        ..types.add(refer('$Route')),
    )
    ..body = Block.of([
      literalList([
        for (final route in server.routes) createParentRef(route),
      ]).statement,
    ]));

  final reflects = Method(
    (p) => p
      ..name = 'reflects'
      ..lambda = true
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Set'
          ..types.add(refer('$Reflect')),
      )
      ..body = Block.of([
        literalSet([
          for (final reflect in server.reflects) createReflect(reflect),
        ]).statement,
      ]),
  );

  final publics = Method(
    (p) => p
      ..name = 'public'
      ..lambda = true
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..types.add(refer('$Route')),
      )
      ..body = Block.of([
        literalList([
          for (final public in server.public)
            refer('$Route').newInstance(
              [literalString(public.path)],
              {
                'method': literalString('GET'),
                'allowedOrigins':
                    refer('$AllowOrigins').newInstanceNamed('all', []),
                'handler': Method(
                  (p) => p
                    ..modifier = MethodModifier.async
                    ..requiredParameters.add(
                      Parameter((p) => p..name = 'context'),
                    )
                    ..body = Block.of([
                      refer('context')
                          .property('response')
                          .property('body')
                          .assign(
                            refer('$File').call([
                              refer('p').property('join').call([
                                literalString('public'),
                                literalString(public.path)
                              ])
                            ]),
                          )
                          .statement,
                    ]),
                ).closure,
              },
            ),
        ]).statement,
      ]),
  );

  final parts = <Spec>[
    main,
    createServer,
    routes,
    reflects,
    publics,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}
