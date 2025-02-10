import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/creators/create_interface_methods.dart';
import 'package:server_client_gen/models/client_controller.dart';

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
