import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/models/client_server.dart';

Spec createServerContent(ClientServer client) {
  return Class(
    (b) => b
      ..modifier = ClassModifier.final$
      ..name = 'Server'
      ..constructors.add(
        Constructor(
          (b) => b,
        ),
      )
      ..fields.addAll([
        for (final controller in client.controllers)
          Field(
            (b) => b
              ..late = true
              ..modifier = FieldModifier.final$
              ..type = refer(controller.interfaceName)
              ..name = controller.interfaceName.toCamelCase()
              ..assignment =
                  refer(controller.implementationName).newInstance([]).code,
          ),
      ]),
  );
}
