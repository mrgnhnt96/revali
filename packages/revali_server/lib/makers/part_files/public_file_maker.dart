import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart' hide Method, AllowOrigins;
import 'package:revali_router_core/revali_router_core_access_control.dart';
import 'package:revali_server/converters/server_server.dart';

PartFile publicFileMaker(ServerServer server, String Function(Spec) formatter) {
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

  final content = formatter(publics);

  return PartFile(
    path: ['definitions', '__public.dart'],
    content: content,
  );
}
