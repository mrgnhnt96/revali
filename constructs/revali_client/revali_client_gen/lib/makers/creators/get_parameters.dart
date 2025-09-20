import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';

Iterable<Parameter> getParameters(
  Iterable<ClientParam> params,
  ClientMethod method,
) sync* {
  final (cookies: _, :body, :query, :headers) = params.separate;

  if (!method.isWebsocket || method.websocketType.canSendAny) {
    final roots = body.roots();

    if (method.websocketBody case final ClientParam param) {
      yield Parameter(
        (b) => b
          ..type = refer(param.type.name)
          ..name = param.name
          ..named = true
          ..required = !(param.type.isNullable || param.hasDefaultValue),
      );
    } else {
      for (final param in body) {
        if (!body.needsAssignment(param, roots)) {
          continue;
        }

        yield _create(param, isStream: method.websocketType.canSendMany);
      }
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

Parameter _create(ClientParam param, {bool isStream = false}) {
  final makeNull = param.type.isNullable || param.hasDefaultValue;

  final typeName = switch (makeNull) {
    true => param.type.nullName,
    false => param.type.name,
  };

  final type = switch (isStream) {
    true => refer('Stream<$typeName>'),
    false => refer(typeName),
  };

  return Parameter(
    (b) => b
      ..name = param.name
      ..named = true
      ..required = !makeNull
      ..type = type,
  );
}
