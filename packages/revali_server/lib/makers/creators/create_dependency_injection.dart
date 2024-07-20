import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

List<Code> createDependencyInjection(ServerServer server) {
  if (server.context.mode.isDebug) {
    return [
      refer('app')
          .property('configureDependencies')
          .call([refer('di')])
          .awaited
          .statement,
      refer('di').property('finishRegistration').call([]).statement,
    ];
  }

  return [
    tryCatch(
      Block.of([
        refer('app')
            .property('configureDependencies')
            .call([refer('di')])
            .awaited
            .statement,
        refer('di').property('finishRegistration').call([]).statement,
      ]),
      Block.of(
        [
          refer('print').call([
            literalString('Failed to configure dependencies:\\n\$e')
          ]).statement,
          refer('server').returned.statement,
        ],
      ),
    ),
  ];
}
