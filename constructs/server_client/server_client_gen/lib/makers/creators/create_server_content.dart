// ignore_for_file: unnecessary_parenthesis, unnecessary_string_interpolations

import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:server_client/server_client.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_app.dart';
import 'package:server_client_gen/models/client_server.dart';

Spec createServerContent(ClientServer client) {
  final ClientApp(:host, :port, :prefix) = client.app;

  // TODO(mrgnhnt): get schema from settings
  final baseUrl = switch (('$host:$port', prefix)) {
    (final String url, null) => 'http://$url',
    (final String url, final String p) when p.isEmpty => 'http://$url',
    (final String url, String()) => 'http://$url/$prefix',
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
                    ..type = refer('Client?')
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
                  .ifNullThen(refer((SessionStorage).name).newInstance([]))
                  .code,
            )
            ..body = Block.of([
              declareFinal('url')
                  .assign(
                    refer('baseUrl').nullSafeProperty('toString').call([]),
                  )
                  .ifNullThen(refer('"$baseUrl"'))
                  .statement,
              const Code(''),
              refer('this')
                  .property('client')
                  .assign(
                    refer((HttpClient).name).newInstance(
                      [],
                      {
                        'client': refer('client').ifNullThen(
                          refer('Client').newInstance([]),
                        ),
                        'baseUrl': refer('url'),
                        'storage': refer('this').property('storage'),
                      },
                    ),
                  )
                  .statement,
              const Code(''),
              refer('this').property('storage').property('save').call(
                [literal('__BASE_URL__'), refer('url')],
              ).statement,
            ]),
        ),
      )
      ..fields.addAll([
        Field(
          (b) => b
            ..late = true
            ..modifier = FieldModifier.final$
            ..type = refer((HttpClient).name)
            ..name = 'client'
            ..late = true,
        ),
        Field(
          (b) => b
            ..late = true
            ..modifier = FieldModifier.final$
            ..type = refer('${(Storage).name}')
            ..name = 'storage',
        ),
      ])
      ..fields.addAll([
        for (final controller in client.controllers)
          Field(
            (b) => b
              ..late = true
              ..modifier = FieldModifier.final$
              ..type = refer(controller.interfaceName)
              ..name = controller.interfaceName.toCamelCase()
              ..assignment =
                  refer(controller.implementationName).newInstance([], {
                'client': refer('client'),
                'storage': refer('storage'),
              }).code,
          ),
      ]),
  );
}
