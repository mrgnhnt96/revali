import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/utils/client_param_extensions.dart';
import 'package:server_client_gen/models/client_param.dart';

Iterable<Parameter> getParameters(Iterable<ClientParam> params) sync* {
  final (
    cookies: _,
    :body,
    :query,
    :headers,
  ) = params.separate;

  final roots = body.roots();
  for (final param in body) {
    if (!body.needsAssignment(param, roots)) {
      continue;
    }

    yield _create(param);
  }

  for (final param in query.followedBy(headers)) {
    yield _create(param);
  }
}

Parameter _create(ClientParam param) {
  return Parameter(
    (b) => b
      ..name = param.name
      ..named = true
      ..required = !param.nullable
      ..type = refer(param.type.name),
  );
}
