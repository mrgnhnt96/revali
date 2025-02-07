import 'package:code_builder/code_builder.dart';
import 'package:server_client/models/client_param.dart';

Iterable<Parameter> getParams(Iterable<ClientParam> params) sync* {
  for (final param in params) {
    yield Parameter(
      (b) => b
        ..name = param.name
        ..named = true
        ..required = !param.nullable
        ..type = refer(param.type.name),
    );
  }
}
