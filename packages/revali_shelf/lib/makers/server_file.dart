import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/makers/utils/meta_route_extensions.dart';

String serverFile(List<MetaRoute> routes, String Function(Spec) formatter) {
  final imports = [
    "import 'dart:io';",
    "import 'dart:convert';",
    "import 'package:examples/repos/repo.dart';",
    "import 'package:examples/utils/logger.dart';",
    "import 'package:shelf/shelf.dart';",
    "import 'package:shelf/shelf_io.dart' as io;",
    "import 'package:revali_router/revali_router.dart';",
    "import 'package:revali_construct/revali_construct.dart';",
    for (final route in routes) "import '../${p.relative(route.filePath)}';",
  ];

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
      ..returns = refer('Future<HttpServer>')
      ..modifier = MethodModifier.async
      ..body = Block.of([
        declareFinal('server')
            .assign(
              refer('io').property('serve').call(
                [
                  Method(
                    (p) => p
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..modifier = MethodModifier.async
                      ..body = Block.of([
                        declareFinal('requestContext')
                            .assign(refer('RequestContext')
                                .newInstance([refer('context')]))
                            .statement,
                        declareFinal('router')
                            .assign(refer('Router').newInstance(
                              [refer('requestContext')],
                              {'routes': refer('routes')},
                            ))
                            .statement,
                        Code('\n'),
                        declareFinal('response')
                            .assign(refer('router')
                                .awaited
                                .property('handle')
                                .call([]))
                            .statement,
                        Code('\n'),
                        refer('response').returned.statement,
                      ]),
                  ).closure,
                  literalString('localhost'),
                  literalNum(8123),
                ],
              ).awaited,
            )
            .statement,
        Code('\n'),
        Code('\t// ensure that the routes are configured correctly'),
        refer('routes').statement,
        Code('\n'),
        refer('print').call(
          [
            literalString(
                'Serving at http://\${server.address.host}:\${server.port}'),
          ],
        ).statement,
        refer('return server').statement,
      ]),
  );

  final routeSpecs = [
    for (final route in routes) createParentRoute(route),
  ];

  final routesVar = declareFinal('routes', late: true)
      .assign(literalList([
        for (final spec in routeSpecs) spec.ref,
      ]))
      .statement;

  final parts = <Spec>[
    main,
    createServer,
    routesVar,
    for (final spec in routeSpecs) spec.method,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}

({Spec ref, Spec method}) createParentRoute(MetaRoute route) {
  final method = Method(
    (p) => p
      ..name = route.handlerName
      ..returns = refer('Route')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = route.className.toCamelCase()
            ..type = refer(route.className),
        ),
      )
      ..body = Block.of([
        refer('Route')
            .newInstance([
              literalString(route.path)
            ], {
              'catchers': literalConstList([]),
              'middlewares': literalConstList([]),
              'guards': literalConstList([]),
              'interceptors': literalConstList([]),
              'meta': literalConstList([]),
              'method': literalNull,
              'handler': literalNull,
              if (route.methods.isNotEmpty)
                'route': literalList([
                  for (final method in route.methods) createRoute(method, route)
                ])
            })
            .returned
            .statement,
      ]),
  );

  final ref = refer(route.handlerName).call([
    refer(route.className).newInstance([]),
  ]);

  return (ref: ref, method: method);
}

Spec createRoute(MetaMethod method, MetaRoute route) {
  var handler =
      refer(route.className.toCamelCase()).property(method.name).call([
    // TODO: Add parameters
  ]);

  if (method.returnType.isFuture) {
    handler = handler.awaited;
  }

  if (!method.returnType.isVoid) {
    handler = declareFinal('result').assign(handler);
  }

  return refer('Route').newInstance([
    literalString(method.path ?? '')
  ], {
    'catchers': literalConstList([]),
    'middlewares': literalConstList([]),
    'guards': literalConstList([]),
    'interceptors': literalConstList([]),
    'meta': literalConstList([]),
    'method': literalString(method.method),
    'handler': Method(
      (p) => p
        ..requiredParameters.add(Parameter((b) => b..name = 'context'))
        ..body = Block.of([
          if (method.returnType.isFuture)
            handler.awaited.statement
          else
            handler.statement,
        ]),
    ).closure,
  });
}
