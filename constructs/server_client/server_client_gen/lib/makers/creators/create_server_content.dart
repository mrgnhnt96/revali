// ignore_for_file: unnecessary_parenthesis

import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:server_client/server_client.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_app.dart';
import 'package:server_client_gen/models/client_server.dart';

Spec createServerContent(ClientServer client) {
  final ClientApp(:host, :port, :prefix) = client.app;

  // TODO(mrgnhnt): get schema from settings
  final baseUrl = switch ((host, port, prefix)) {
    (String(), int(), null) => 'http://$host:$port',
    (String(), int(), final String p) when p.isEmpty => 'http://$host:$port',
    (String(), int(), String()) => 'http://$host:$port/$prefix',
  };

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
                    ..named = true
                    ..type = refer('${(HttpClient).name}?')
                    ..name = 'client',
                ),
                Parameter(
                  (b) => b
                    ..named = true
                    ..type = refer('${(Storage).name}?')
                    ..name = 'storage',
                ),
                Parameter(
                  (b) => b
                    ..named = true
                    ..type = refer('${(Uri).name}?')
                    ..name = 'baseUrl',
                ),
              ],
            )
            ..initializers.add(
              refer('storage')
                  .assign(refer('storage'))
                  .ifNullThen(refer((SessionStorage).name))
                  .code,
            )
            ..body = Block.of([
              declareFinal('url')
                  .assign(refer('baseUrl').nullSafeProperty('toString'))
                  .ifNullThen(literalString(baseUrl))
                  .statement,
            ]),
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
