import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/route_file_maker.dart';
import 'package:revali_server/makers/server_file_maker.dart';

class RevaliServerConstruct implements ServerConstruct {
  const RevaliServerConstruct();

  @override
  ServerFile generate(RevaliContext context, MetaServer server) {
    final serverServer = ServerServer.fromMeta(context, server);
    serverServer.validate();

    final formatter = DartFormatter();
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      // return spec.accept(emitter).toString();
      return formatter.format(spec.accept(emitter).toString());
    }

    final content = serverFile(serverServer, format);

    return ServerFile(
      content: content,
      parts: [
        for (final route in serverServer.routes) routeFileMaker(route, format),
      ],
    );
  }
}
