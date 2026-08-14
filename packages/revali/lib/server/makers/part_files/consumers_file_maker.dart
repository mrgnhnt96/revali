// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_server.dart';
import 'package:revali/server/makers/creators/create_class.dart';
import 'package:revali/server/makers/utils/type_extensions.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart' hide Method;

/// Emits `registerConsumers`, which subscribes every `@Consumes` handler.
///
/// Mirrors `routes(di)`: controllers are constructed the same way, so a
/// singleton controller is shared with its routes rather than rebuilt for
/// messages.
///
/// Returns null when nothing is annotated, so an app that uses no messaging
/// gains no file and no generated wiring at all.
PartFile? consumersFileMaker(
  ServerServer server,
  String Function(Spec) formatter,
) {
  final withConsumers = server.routes
      .where((route) => route.consumers.isNotEmpty)
      .toList();

  if (withConsumers.isEmpty) {
    return null;
  }

  final register = Method(
    (p) => p
      ..name = 'registerConsumers'
      ..modifier = MethodModifier.async
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Future'
          ..types.add(refer('void')),
      )
      ..requiredParameters.addAll([
        Parameter(
          (p) => p
            ..name = 'registry'
            ..type = refer((ConsumerRegistry).name),
        ),
        Parameter(
          (p) => p
            ..name = 'di'
            ..type = refer((DI).name),
        ),
      ])
      ..body = Block.of([
        for (final route in withConsumers)
          if (route.type == InstanceType.singleton)
            declareFinal(
              '_${route.variableName}',
            ).assign(createClass(route)).statement,
        const Code(''),
        for (final route in withConsumers)
          for (final consumer in route.consumers)
            refer('registry')
                .property('consume')
                .call(
                  [literalString(consumer.topic)],
                  {
                    'group': literalString(consumer.group),
                    'onMessage': Method(
                      (b) => b
                        ..lambda = true
                        ..requiredParameters.add(
                          Parameter((p) => p..name = 'message'),
                        )
                        ..body =
                            switch (route.type) {
                              InstanceType.singleton => refer(
                                '_${route.variableName}',
                              ),
                              InstanceType.factory => createClass(route),
                            }.property(consumer.name).call([
                              // A handler may take the message or nothing.
                              if (consumer.params.isNotEmpty) refer('message'),
                            ]).code,
                    ).closure,
                  },
                )
                .awaited
                .statement,
      ]),
  );

  final content = formatter(register);

  return PartFile(path: ['definitions', '__consumers'], content: content);
}
