import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/makers/creators/get_path_params.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

Method createSignature(ClientMethod method, {Code? body}) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        ClientType(isStringContent: true) => refer('Future<String>'),
        ClientType(isStream: true, typeArguments: [ClientType(:final name)]) ||
        ClientType(isFuture: true, typeArguments: [ClientType(:final name)]) ||
        ClientType(isStream: false, isFuture: false, :final name)
            when method.isWebsocket =>
          refer('Stream<$name>'),
        ClientType(:final isStream, isStringContent: true) ||
        ClientType(
          :final isStream,
          typeArguments: [ClientType(isStringContent: true)]
        ) =>
          switch (isStream) {
            true => refer('Stream<String>'),
            false => refer('Future<String>'),
          },
        ClientType(isFuture: true, :final name) ||
        ClientType(isStream: true, :final name) =>
          refer(name),
        ClientType(:final name) => refer('Future<$name>')
      }
      ..optionalParameters.addAll(getPathParams(method))
      ..optionalParameters.addAll(getParameters(method.allParams, method))
      ..modifier = switch (method.returnType) {
        ClientType(isStream: true) => MethodModifier.asyncStar,
        _ when method.isWebsocket && method.websocketType.canReceive =>
          MethodModifier.asyncStar,
        _ when body == null => null,
        _ => MethodModifier.async,
      }
      ..annotations.addAll([
        if (body != null) refer('override'),
      ])
      ..body = body,
  );
}
