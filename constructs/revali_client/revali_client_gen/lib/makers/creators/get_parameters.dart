import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';

Iterable<Parameter> getParameters(
  Iterable<ClientParam> params,
  ClientMethod method,
) sync* {
  final (
    cookies: _,
    :body,
    :query,
    :headers,
  ) = params.separate;

  if (!method.isWebsocket || method.websocketType.canSendAny) {
    final roots = body.roots();
    for (final param in body) {
      if (!body.needsAssignment(param, roots)) {
        continue;
      }

      yield _create(
        param,
        isStream: method.websocketType.canSendMany,
      );
    }
  }

  for (final param in query) {
    yield _create(param);
  }

  if (method.isWebsocket) {
    return;
  }

  for (final param in headers) {
    yield _create(param);
  }
}

Parameter _create(
  ClientParam param, {
  bool isStream = false,
}) {
  final type = switch (isStream) {
    true => refer('Stream<${param.type.name}>'),
    false => refer(param.type.name),
  };
  return Parameter(
    (b) => b
      ..name = param.name
      ..named = true
      ..required = !param.nullable
      ..type = type,
  );
}
