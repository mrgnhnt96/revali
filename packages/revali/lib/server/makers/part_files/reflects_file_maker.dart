// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_server.dart';
import 'package:revali/server/makers/creators/create_reflect.dart';
import 'package:revali/server/makers/utils/type_extensions.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_core/revali_core.dart';

PartFile reflectsFileMaker(
  ServerServer server,
  String Function(Spec) formatter,
) {
  final reflects = Method(
    (p) => p
      ..name = 'reflects'
      ..lambda = true
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Set'
          ..types.add(refer((ReflectData).name)),
      )
      ..body = Block.of([
        literalSet([
          for (final reflect in server.reflects) createReflect(reflect),
        ]).statement,
      ]),
  );

  final content = formatter(reflects);

  return PartFile(path: ['definitions', '__reflects'], content: content);
}
