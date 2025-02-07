import 'package:code_builder/code_builder.dart';
import 'package:server_client/makers/creators/create_interface_method.dart';
import 'package:server_client/models/client_controller.dart';

Iterable<Method> createInterfaceMethods(ClientController controller) sync* {
  for (final method in controller.methods) {
    yield createInterfaceMethod(method);
  }
}
