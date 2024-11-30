import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/utils/try_catch.dart';

List<Code> createDependencyInjection(ServerServer server) {
  if (server.context.mode.isRelease) {
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
            literalString(r'Failed to configure dependencies:\n$e'),
          ]).statement,
          refer('server').returned.statement,
        ],
      ),
    ),
  ];
}
