import 'package:code_builder/code_builder.dart';

import '../../models/client_controller.dart';
import 'create_interface_method.dart';

Iterable<Method> createInterfaceMethods(ClientController controller) sync* {
  for (final method in controller.methods) {
    yield createInterfaceMethod(method);
  }
}
