// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart' hide AllowOrigins, Method;
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/creators/create_parent_ref.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

PartFile routesFileMaker(ServerServer server, String Function(Spec) formatter) {
  final routes = Method(
    (p) => p
      ..name = 'routes'
      ..lambda = true
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'di'
            ..type = refer((DI).name),
        ),
      )
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..types.add(refer((Route).name)),
      )
      ..body = Block.of([
        literalList([
          for (final route in server.routes) createParentRef(route),
        ]).statement,
      ]),
  );

  final content = formatter(routes);

  return PartFile(
    path: ['definitions', '__routes'],
    content: content,
  );
}
