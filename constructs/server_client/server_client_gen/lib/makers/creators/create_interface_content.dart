import 'package:code_builder/code_builder.dart';

import '../../models/client_controller.dart';
import 'create_interface_methods.dart';

Spec createInterfaceContent(ClientController controller) {
  return Class(
    (b) => b
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..name = controller.interfaceName
      ..constructors.add(
        Constructor(
          (b) => b..constant = true,
        ),
      )
      ..methods.addAll(createInterfaceMethods(controller)),
  );
}
