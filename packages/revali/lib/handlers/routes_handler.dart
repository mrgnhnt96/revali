import 'package:file/file.dart';
import 'package:revali/ast/file_traverser.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';

class RoutesHandler with DirectoriesMixin {
  RoutesHandler({
    required this.fs,
    required this.rootPath,
  });

  final FileSystem fs;
  final String rootPath;

  Future<MetaServer> parse() async {
    final root = await rootOf(rootPath);

    final routesDir = await root.getRoutes();

    if (routesDir == null || !await routesDir.exists()) {
      return MetaServer(routes: [], apps: [MetaAppConfig.defaultConfig()]);
    }

    final traverser = FileTraverser(fs);

    final entities = await routesDir
        .list(
          recursive: true,
          followLinks: false,
        )
        .toList();

    final routes = <MetaRoute>[];
    final apps = <MetaAppConfig>[];

    for (final entity in entities) {
      if (entity is Directory) continue;

      if (!await fs.isFile(entity.path)) {
        continue;
      }

      final file = fs.file(entity.path);

      final route = await traverser.parseRoute(file);

      if (route != null) {
        routes.add(route);
        continue;
      }

      final app = await traverser.parseApp(file);

      if (app != null) {
        apps.add(app);
        continue;
      }
    }

    if (apps.isEmpty) {
      apps.add(MetaAppConfig.defaultConfig());
    }

    return MetaServer(
      routes: routes,
      apps: apps,
    );
  }
}
