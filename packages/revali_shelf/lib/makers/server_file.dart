import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

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
    "import '../routes/user.controller.dart' as user_controller;",
    "import 'package:revali_construct/revali_construct.dart';",
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
              refer('await io.serve').call(
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
              ),
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
                    .call([])
                    .property('add')
                    .call(
                      [
                        refer('Router').call([]).cascade('mount').call(
                              [
                                literalString('/user'),
                                refer('(context) => user()')
                                    .call([refer('context')]),
                              ],
                            ),
                      ],
                    )
                    .property('handler'),
              ],
            )
            .returned
            .statement,
      ]),
  );

  final user = Method(
    (b) => b
      ..name = 'user'
      ..returns = refer('Handler')
      ..body = Block.of([
        declareFinal('controller')
            .assign(
              refer('DI').property('instance').property('get').call(
                [],
                {},
                [
                  refer('user_controller.ThisController'),
                ],
              ),
            )
            .statement,
        refer('return Router').call([])
            // .property('add')
            // .call(
            //   [
            //     literalString('GET'),
            //     literalString('/'),
            //     refer('(context) => _userListPeople(controller)')
            //         .call([refer('context')]),
            //   ],
            // )
            // .property('add')
            // .call(
            //   [
            //     literalString('GET'),
            //     literalString('/<id>'),
            //     refer('(context) => _userGetNewPerson(controller)')
            //         .call([refer('context')]),
            //   ],
            // )
            // .property('add')
            // .call(
            //   [
            //     literalString('POST'),
            //     literalString('/create'),
            //     refer('(context) => _userCreate(controller)')
            //         .call([refer('context')]),
            //   ],
            // )
            .statement,
      ]),
  );

  final parts = <Spec>[
    main,
    createServer,
    _root,
    user,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}
