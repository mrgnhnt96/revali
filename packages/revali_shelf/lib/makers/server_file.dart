import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;
import 'package:revali_shelf/converters/shelf_parent_route.dart';
import 'package:revali_shelf/converters/shelf_server.dart';

String serverFile(ShelfServer server, String Function(Spec) formatter) {
  final imports = [
    "import 'dart:io';",
    "import 'dart:convert';",
    "import 'package:examples/repos/repo.dart';",
    "import 'package:examples/utils/logger.dart';",
    "import 'package:shelf/shelf.dart';",
    "import 'package:shelf/shelf_io.dart' as io;",
    "import 'package:revali_router/revali_router.dart';",
    "import 'package:revali_router_annotations/revali_router_annotations.dart';",
    "import 'package:revali_construct/revali_construct.dart';",
    for (final imprt in server.imports) "import '../${p.relative(imprt)}';",
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
      ..returns = TypeReference(
        (p) => p
          ..symbol = 'Future'
          ..types.add(
            refer('HttpServer'),
          ),
      )
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
        Code('\n'),
        refer('server').returned.statement,
      ]),
  );

  final routesVar = Method((p) => p
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
    routesVar,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}

Spec createParentReference(ShelfParentRoute route) {
  return refer(route.handlerName).call([
    refer(route.className).newInstance([]),
  ]);
}
