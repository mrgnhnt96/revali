import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/part_files/public_file_maker.dart';
import 'package:revali_server/makers/part_files/reflects_file_maker.dart';
import 'package:revali_server/makers/part_files/route_file_maker.dart';
import 'package:revali_server/makers/part_files/routes_file_maker.dart';
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

    return ServerFile(
      content: serverFile(serverServer, format),
      parts: [
        for (final route in serverServer.routes) routeFileMaker(route, format),
        reflectsFileMaker(serverServer, format),
        publicFileMaker(serverServer, format),
        routesFileMaker(serverServer, format),
      ],
    );
  }
}
