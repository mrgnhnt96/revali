import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/makers/creators/get_path_params.dart';
import 'package:revali_client_gen/models/client_method.dart';

Method createSignature(ClientMethod method, {Code? body}) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        final e when e.isStringContent => refer('Future<String>'),
        final e when e.isFuture || e.isStream => refer(e.name),
        final e => refer('Future<${e.name}>')
      }
      ..optionalParameters.addAll(getPathParams(method))
      ..optionalParameters.addAll(getParameters(method.allParams, method))
      ..modifier = switch (body) {
        null => null,
        _ when method.returnType.isStream => MethodModifier.asyncStar,
        _ => MethodModifier.async,
      }
      ..annotations.addAll([
        if (body != null) refer('override'),
      ])
      ..body = body,
  );
}
