import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method, AllowOrigins;
import 'package:revali_server/revali_server.dart';

List<Code> createRoutesVariable(ServerServer server) {
  if (server.context.mode.isDebug) {
    return [
      declareVar('_routes')
          .assign(refer('routes').call([refer('di')]))
          .statement,
    ];
  }

  return [
    declareVar(
      '_routes',
      type: TypeReference(
        (b) => b..symbol = 'Iterable<${(Route).name}>',
      ),
    ).statement,
    tryCatch(
      Block.of([
        refer('_routes').assign(refer('routes').call([refer('di')])).statement,
      ]),
      Block.of([
        refer('print')
            .call([literalString('Failed to create routes:\\n\$e')]).statement,
        refer('server').returned.statement,
      ]),
    ),
  ];
}