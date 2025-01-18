// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/utils/try_catch.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

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
        declareFinal('dependencyInjection')
            .assign(refer('app').property('initializeDI').call([]))
            .statement,
        refer('app')
            .property('configureDependencies')
            .call([refer('dependencyInjection')])
            .awaited
            .statement,
        refer('di')
            .assign(
              refer((DIHandler).name)
                  .newInstance([refer('dependencyInjection')]),
            )
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
