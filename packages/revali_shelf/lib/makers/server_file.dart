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
    "import 'package:shelf_router/shelf_router.dart';",
    "import 'package:revali_annotations/revali_annotations.dart';",
    "import 'package:revali_construct/revali_construct.dart';",
    for (final route in routes) "import '../${p.relative(route.filePath)}';",
  ];

  final main = Method(
    (b) => b
      ..name = 'main'
      ..returns = refer('void')
      ..modifier = MethodModifier.async
      ..body = Block.of([
        // dependencies can't be registered here, we aren't ASTing any of the lib's
        // code, where the dependencies are defined
        // This means that we will need to have a file or something that the user defines as the
        // entry point for the server, where they can register their dependencies
        refer('_registerDependencies').call([]).statement,
        refer('_registerControllers').call([]).statement,
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
                  refer('Cascade')
                      .call([])
                      .property('add')
                      .call(
                        [
                          refer('_root').call([]),
                        ],
                      )
                      .property('handler'),
                  literalString('localhost'),
                  literalNum(8123),
                ],
              ).awaited,
            )
            .statement,
        refer('server')
            .property('autoCompress')
            .assign(literalBool(true))
            .statement,
        refer('print').call(
          [
            literalString(
                'Serving at http://\${server.address.host}:\${server.port}'),
          ],
        ).statement,
        refer('return server').statement,
      ]),
  );

  var router = refer('Router').newInstance([]);

  for (final route in routes) {
    router = router.cascade('mount').call(
      [
        literalString(route.cleanPath),
        Method(
          (b) => b
            ..lambda = true
            ..requiredParameters.add(Parameter((b) => b..name = 'context'))
            ..body = Block.of([
              refer(route.handlerName).call([]).call([refer('context')]).code,
            ]),
        ).closure,
      ],
    );
  }

  final _root = Method(
    (b) => b
      ..name = '_root'
      ..returns = refer('Handler')
      ..body = Block.of([
        refer('Pipeline')
            .call([])
            .property('addHandler')
            .call(
              [
                refer('Cascade')
                    .newInstance([])
                    .property('add')
                    .call([router])
                    .property('handler'),
              ],
            )
            .returned
            .statement,
      ]),
  );

  final parts = <Spec>[
    main,
    createServer,
    _root,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}
