import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/models/client_param.dart';

Iterable<Parameter> getParameters(Iterable<ClientParam> params) sync* {
  for (final param in params) {
    // Skip cookie parameters, these will be handled with the storage
    if (param.position == ParameterPosition.cookie) {
      continue;
    }

    yield Parameter(
      (b) => b
        ..name = param.name
        ..named = true
        ..required = !param.nullable
        ..type = refer(param.type.name),
    );
  }
}
