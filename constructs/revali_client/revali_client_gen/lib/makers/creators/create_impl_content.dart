// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_client_gen/makers/creators/create_impl_method.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_controller.dart';

Spec createImplContent(ClientController controller) {
  return Class(
    (b) => b
      ..name = controller.implementationName
      ..implements.add(refer(controller.interfaceName))
      ..constructors.add(
        Constructor(
          (b) => b
            ..constant = true
            ..optionalParameters.addAll([
              Parameter(
                (b) => b
                  ..name = 'client'
                  ..type = refer((RevaliClient).name)
                  ..named = true
                  ..required = true,
              ),
              Parameter(
                (b) => b
                  ..name = 'storage'
                  ..type = refer((Storage).name)
                  ..named = true
                  ..required = true,
              ),
              if (controller.hasWebsockets)
                Parameter(
                  (b) => b
                    ..name = 'websocket'
                    ..type = refer('WebSocketConnect')
                    ..named = true
                    ..required = true,
                ),
            ])
            ..initializers.addAll([
              refer('_client').assign(refer('client')).code,
              refer('_storage').assign(refer('storage')).code,
              if (controller.hasWebsockets)
                refer('_websocket').assign(refer('websocket')).code,
            ]),
        ),
      )
      ..fields.addAll([
        Field(
          (b) => b
            ..modifier = FieldModifier.final$
            ..name = '_client'
            ..type = refer((RevaliClient).name),
        ),
        Field(
          (b) => b
            ..modifier = FieldModifier.final$
            ..name = '_storage'
            ..type = refer((Storage).name),
        ),
        if (controller.hasWebsockets)
          Field(
            (b) => b
              ..modifier = FieldModifier.final$
              ..name = '_websocket'
              ..type = refer('WebSocketConnect'),
          ),
      ])
      ..methods.addAll([
        for (final method in controller.methods)
          if (!method.isExcluded) createImplMethod(method),
      ]),
  );
}
