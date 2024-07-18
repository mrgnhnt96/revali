import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart' hide Method;
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

PartFile publicFileMaker(ServerServer server, String Function(Spec) formatter) {
  final publics = Method(
    (p) => p
      ..name = 'public'
      ..lambda = true
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..types.add(refer((Route).name)),
      )
      ..body = Block.of([
        literalList([
          for (final public in server.public)
            refer((Route).name).newInstance(
              [literalString(public.path)],
              {
                'method': literalString('GET'),
                'allowedOrigins': refer((AllowedOriginsImpl).name)
                    .newInstanceNamed('all', []),
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
                            refer((File).name).call([
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

  final content = formatter(publics);

  return PartFile(
    path: ['definitions', '__public.dart'],
    content: content,
  );
}
