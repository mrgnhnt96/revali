import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/makers/creators/get_path_params.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

Method createSignature(ClientMethod method, {Code? body}) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = createReturnType(
        method.returnType,
        isSse: method.isSse,
        isWebsocket: method.isWebsocket,
      )
      ..optionalParameters.addAll(getPathParams(method))
      ..optionalParameters.addAll(getParameters(method.allParams, method))
      ..modifier = switch (method.returnType) {
        ClientType(isStream: true) when method.isSse =>
          MethodModifier.asyncStar,
        ClientType(isStream: true, isBytes: true) => MethodModifier.asyncStar,
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

Reference createReturnType(
  ClientType type, {
  required bool isSse,
  required bool isWebsocket,
  bool skipRoot = false,
}) {
  return TypeReference(
    (b) => b
      ..symbol = switch (type) {
        ClientType(isStream: true) when isSse => 'Stream',
        ClientType(isStream: true) when isWebsocket => 'Stream',
        ClientType(isStream: true, isBytes: true) => 'Stream',
        ClientType(isStream: true) => 'Future',
        ClientType(isFuture: true) => 'Future',
        ClientType(isRoot: true, isFuture: false) when !skipRoot => 'Future',
        ClientType(isMap: true) => 'Map',
        ClientType(:final iterableType?) => iterableType.symbol,
        ClientType(isStringContent: true) => 'String',
        ClientType(:final name) => name,
      }
      ..isNullable = type.isNullable
      ..types.addAll([
        if (type case ClientType(isRoot: true, isFuture: false, isStream: false)
            when !skipRoot)
          createReturnType(
            type,
            isSse: isSse,
            isWebsocket: isWebsocket,
            skipRoot: true,
          )
        else if (type case ClientType(typeArguments: final types))
          for (final type in types)
            createReturnType(type, isSse: isSse, isWebsocket: isWebsocket),
      ]),
  );
}
