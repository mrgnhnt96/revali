// ignore_for_file: unnecessary_parenthesis

import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_server.dart';

Spec createServerContent(ClientServer client) {
  return Class(
    (b) => b
      ..modifier = ClassModifier.final$
      ..name = 'Server'
      ..constructors.add(
        Constructor(
          (b) => b
            ..optionalParameters.addAll(
              [
                Parameter(
                  (b) => b
                    ..name = 'client'
                    ..type = refer('${(HttpClient).name}?')
                    ..named = true,
                ),
              ],
            ),
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
