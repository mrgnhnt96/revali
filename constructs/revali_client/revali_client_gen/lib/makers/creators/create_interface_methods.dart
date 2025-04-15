import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_signature.dart';
import 'package:revali_client_gen/models/client_controller.dart';

Iterable<Method> createInterfaceMethods(ClientController controller) sync* {
  for (final method in controller.methods) {
    if (method.isExcluded) continue;

    yield createSignature(method);
  }
}
