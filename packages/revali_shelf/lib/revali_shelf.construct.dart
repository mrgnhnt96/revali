import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_server.dart';
import 'package:revali_shelf/makers/route_file_maker.dart';
import 'package:revali_shelf/makers/server_file.dart';

class RevaliShelfConstruct implements ServerConstruct {
  const RevaliShelfConstruct();

  @override
  ServerFile generate(MetaServer server) {
    final shelfServer = ShelfServer.fromMeta(server);

    final formatter = DartFormatter();
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      return formatter.format(spec.accept(emitter).toString());
    }

    final content = serverFile(shelfServer, format);

    return ServerFile(
      content: content,
      parts: [
        for (final route in shelfServer.routes) routeFileMaker(route, format)
      ],
    );
  }
}
