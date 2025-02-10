import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/utils/get_params.dart';
import 'package:server_client_gen/models/client_method.dart';

Method createInterfaceMethod(ClientMethod method) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        final e when e.isStream => refer(e.name),
        final e => refer('Future<${e.name}>')
      }
      ..optionalParameters.addAll(getParams(method.parameters)),
  );
}
