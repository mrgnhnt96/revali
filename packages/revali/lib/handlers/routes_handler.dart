import 'package:file/file.dart';
import 'package:revali/ast/route_traverser.dart';
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
      return MetaServer(routes: []);
    }

    final traverser = RouteTraverser(
      fs: fs,
    );

    final entities = await routesDir
        .list(
          recursive: true,
          followLinks: false,
        )
        .toList();

    final routes = <MetaRoute>[];

    for (final entity in entities) {
      if (entity is Directory) continue;

      if (!await fs.isFile(entity.path)) {
        continue;
      }

      final file = fs.file(entity.path);

      final route = await traverser.parse(file);

      if (route == null) {
        continue;
      }

      routes.add(route);
    }

    return MetaServer(routes: routes);
  }
}
