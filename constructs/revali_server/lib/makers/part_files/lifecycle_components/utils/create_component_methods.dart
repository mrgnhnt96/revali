import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Iterable<Code> createComponentMethods(
  Iterable<ServerLifecycleComponentMethod> methods, {
  Map<String, Expression> inferredParams = const {},
}) sync* {
  for (final method in methods) {
    final params = getParams(method.parameters, inferredParams: inferredParams);

    final usesBody = method.parameters.any((e) => e.annotations.body != null);

    final code = Method(
      (p) => p
        ..modifier = switch (usesBody) {
          true => MethodModifier.async,
          _ => null,
        }
        ..body = Block.of([
          if (usesBody)
            refer('context')
                .property('request')
                .property('resolvePayload')
                .call([])
                .awaited
                .statement,
          const Code('\n'),
          refer('component')
              .property(method.name)
              .call(params.positioned, params.named)
              .returned
              .statement,
        ]),
    );

    yield code.closure.code;
  }
}
