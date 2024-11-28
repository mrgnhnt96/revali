import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_server.dart';
import 'package:revali_server/makers/part_files/lifecycle_components_files_maker.dart';
import 'package:revali_server/makers/part_files/public_file_maker.dart';
import 'package:revali_server/makers/part_files/reflects_file_maker.dart';
import 'package:revali_server/makers/part_files/route_file_maker.dart';
import 'package:revali_server/makers/part_files/routes_file_maker.dart';
import 'package:revali_server/makers/server_file_maker.dart';
import 'package:revali_server/models/options.dart';

class RevaliServerConstruct implements ServerConstruct {
  const RevaliServerConstruct(this.options);

  final Options options;

  @override
  ServerDirectory generate(RevaliContext context, MetaServer server) {
    final serverServer = ServerServer.fromMeta(context, server)..validate();

    final formatter = DartFormatter();
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      return formatter.format(spec.accept(emitter).toString());
    }

    final components = serverServer.routes
        .expand((e) => e.routes)
        .expand((e) => e.annotations.lifecycleComponents);

    final lifecycleComponentFiles = components
        .expand((e) => lifecycleComponentFilesMaker(e, format))
        .toList();

    return ServerDirectory(
      serverFile: ServerFile(
        content: serverFile(serverServer, format, options: options),
        parts: [
          for (final route in serverServer.routes)
            routeFileMaker(route, format),
          reflectsFileMaker(serverServer, format),
          publicFileMaker(serverServer, format),
          routesFileMaker(serverServer, format),
          ...lifecycleComponentFiles,
        ],
      ),
    );
  }
}
