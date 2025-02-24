// ignore_for_file: unnecessary_parenthesis, unnecessary_string_interpolations

import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_app.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_client_gen/models/settings.dart';

Spec createServerContent(ClientServer client, Settings settings) {
  final ClientApp(:host, :port, :prefix) = client.app;

  final Settings(:scheme) = settings;
  final baseUrl = switch (('$host:$port', prefix)) {
    (final String url, null) => '$scheme://$url',
    (final String url, final String p) when p.isEmpty => '$scheme://$url',
    (final String url, String()) => '$scheme://$url/$prefix',
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
              ..name = controller.simpleName.toCamelCase()
              ..assignment =
                  refer(controller.implementationName).newInstance([], {
                'client': refer('client'),
                'storage': refer('storage'),
              }).code,
          ),
      ])
      ..methods.addAll([
        if (settings.integrateGetIt)
          Method(
            (b) => b
              ..name = 'register'
              ..returns = refer('void')
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..type = refer('GetIt')
                    ..name = 'getIt',
                ),
              )
              ..body = Block.of([
                for (final controller in client.controllers)
                  refer('getIt').property('registerLazySingleton').call([
                    Method(
                      (b) => b
                        ..lambda = true
                        ..body =
                            refer(controller.simpleName.toCamelCase()).code,
                    ).closure,
                  ]).statement,
              ]),
          ),
      ]),
  );
}
