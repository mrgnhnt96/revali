import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/creators/create_reflect.dart';

PartFile reflectsFileMaker(
    ServerServer server, String Function(Spec) formatter) {
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

  final content = formatter(reflects);

  return PartFile(
    path: ['definitions', '__reflects.dart'],
    content: content,
  );
}
