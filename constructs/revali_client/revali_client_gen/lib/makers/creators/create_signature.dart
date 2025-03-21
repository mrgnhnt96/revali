import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_return_type.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/makers/creators/get_path_params.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

Method createSignature(ClientMethod method, {Code? body}) {
  final returnType = method.returnType.typeForClient;
  return Method(
    (b) => b
      ..name = method.name
      ..returns = createReturnType(returnType)
      ..optionalParameters.addAll(getPathParams(method.params))
      ..optionalParameters.addAll(getParameters(method.allParams, method))
      ..modifier = switch (returnType) {
        ClientType(isStream: true) => MethodModifier.asyncStar,
        _ when body == null => null,
        _ => MethodModifier.async,
      }
      ..annotations.addAll([
        if (body != null) refer('override'),
      ])
      ..body = body,
  );
}
