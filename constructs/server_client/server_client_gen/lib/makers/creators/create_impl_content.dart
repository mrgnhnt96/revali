import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/creators/create_impl_method.dart';
import 'package:server_client_gen/models/client_controller.dart';

Spec createImplContent(ClientController controller) {
  return Class(
    (b) => b
      ..name = controller.implementationName
      ..implements.add(refer(controller.interfaceName))
      ..constructors.add(
        Constructor(
          (b) => b
            ..constant = true
            ..requiredParameters.add(
              Parameter(
                (b) => b
                  ..name = '_client'
                  ..toThis = true,
              ),
            ),
        ),
      )
      ..fields.add(
        Field(
          (b) => b
            ..modifier = FieldModifier.final$
            ..name = '_client'
            ..type = refer('Client'),
        ),
      )
      ..methods.addAll(controller.methods.map(createImplMethod)),
  );
}
