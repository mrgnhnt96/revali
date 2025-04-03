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
                    ..type = refer('HttpClient?')
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
                if (client.hasWebsockets)
                  Parameter(
                    (b) => b
                      ..named = true
                      ..type = refer('WebSocketConnect?')
                      ..name = 'websocket',
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
                    refer((RevaliClient).name).newInstance(
                      [],
                      {
                        'client': refer('client').ifNullThen(
                          refer('HttpPackageClient').newInstance([]),
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
              if (client.hasWebsockets) ...[
                const Code(''),
                refer('this')
                    .property('websocket')
                    .assign(
                      refer('websocket').ifNullThen(
                        refer('WebSocketChannel').property('connect'),
                      ),
                    )
                    .statement,
              ],
            ]),
        ),
      )
      ..fields.addAll([
        Field(
          (b) => b
            ..late = true
            ..modifier = FieldModifier.final$
            ..type = refer((RevaliClient).name)
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
        if (client.hasWebsockets)
          Field(
            (b) => b
              ..late = true
              ..modifier = FieldModifier.final$
              ..type = refer('WebSocketConnect')
              ..name = 'websocket',
          ),
      ])
      ..fields.addAll([
        for (final controller in client.controllers)
          if (!controller.isExcluded)
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
                  if (controller.hasWebsockets) 'websocket': refer('websocket'),
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
