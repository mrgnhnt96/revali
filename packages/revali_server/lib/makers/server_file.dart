import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_app.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_parent_route.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/route_file_maker.dart';
import 'package:revali_server/makers/utils/try_catch.dart';

String serverFile(ServerServer server, String Function(Spec) formatter) {
  final imports = [
    "import 'dart:io';",
    "import 'dart:convert';",
    "import 'package:revali_router/revali_router.dart';",
    "import 'package:revali_annotations/revali_annotations.dart';",
    "import 'package:revali_router_annotations/revali_router_annotations.dart';",
    "import 'package:revali_construct/revali_construct.dart';",
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

  final reflects = Method(
    (p) => p
      ..name = 'reflects'
      ..lambda = true
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Set'
          ..types.add(refer('Reflect')),
      )
      ..body = Block.of([
        literalSet([
          for (final reflect in server.reflects) createReflect(reflect),
        ]).statement,
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
              }).awaited)
              .statement,
          Block.of([
            refer('print').call(
                [literalString('Failed to bind server:\\n\$e')]).statement,
            refer('exit').call([literalNum(1)]).statement,
          ]),
        ),
        Code('\n'),
        refer('handleRequests').call(
          [
            refer('server'),
            Method(
              (p) => p
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'context'),
                )
                ..modifier = MethodModifier.async
                ..body = Block.of([
                  declareVar('_routes').assign(refer('routes')).statement,
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
                          refer('Route').newInstance([
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
                      .assign(refer('Router').newInstance(
                        [refer('context')],
                        {
                          'routes': refer('_routes'),
                          'reflects': refer('reflects'),
                          if (server.app case final app?
                              when app.globalRouteAnnotations.hasAnnotations)
                            'globalModifiers':
                                refer('RouteModifiers').newInstance([], {
                              ...createModifierArgs(
                                annotations: app.globalRouteAnnotations,
                              )
                            })
                        },
                      ))
                      .statement,
                  Code('\n'),
                  declareFinal('response')
                      .assign(
                          refer('router').awaited.property('handle').call([]))
                      .statement,
                  Code('\n'),
                  refer('response').returned.statement,
                ]),
            ).closure,
          ],
        ).statement,
        Code('\n'),
        Code('\t// ensure that the routes are configured correctly'),
        tryCatch(
          refer('routes').statement,
          Block.of([
            refer('print').call(
                [literalString('Failed to setup routes:\\n\$e')]).statement,
            refer('exit').call([literalNum(1)]).statement
          ]),
        ),
        Code('\n'),
        refer('app').property('onServerStarted').nullSafeProperty('call').call(
          [refer('server')],
        ).statement,
        Code('\n'),
        refer('server').returned.statement,
      ]),
  );

  final routes = Method((p) => p
    ..name = 'routes'
    ..lambda = true
    ..type = MethodType.getter
    ..returns = TypeReference(
      (b) => b
        ..symbol = 'List'
        ..types.add(refer('Route')),
    )
    ..body = Block.of([
      literalList([
        for (final route in server.routes) createParentReference(route),
      ]).statement,
    ]));

  final parts = <Spec>[
    main,
    createServer,
    routes,
    reflects,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}

Spec createParentReference(ServerParentRoute route) {
  final (:positioned, :named) = getParams(route.params);

  return refer(route.handlerName).call([
    refer(route.className).newInstance(positioned, named),
  ]);
}

Spec createReflect(ServerReflect possibleReflect) {
  final reflect = possibleReflect.valid;

  if (reflect == null) {
    return Code('');
  }

  Expression metaExp(MapEntry<String, Iterable<ServerMimic>> data) {
    final MapEntry(:key, value: meta) = data;

    var m = refer('m').index(literalString(key));

    for (final item in meta) {
      m = m.cascade('add').call([mimic(item)]);
    }

    return m;
  }

  return refer('Reflect').newInstance(
    [
      refer(reflect.className),
    ],
    {
      'metas': Method(
        (p) => p
          ..requiredParameters.add(
            Parameter((p) => p..name = 'm'),
          )
          ..body = Block.of([
            for (final meta in reflect.metas.entries) metaExp(meta).statement,
          ]),
      ).closure,
    },
  );
}

Expression createApp(ServerApp app) {
  final (:positioned, :named) = getParams(app.params);

  var expression = refer(app.className);

  if (app.constructor.isEmpty) {
    return expression.newInstance(positioned, named);
  } else {
    return expression.newInstanceNamed(app.constructor, positioned, named);
  }
}
