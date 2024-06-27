import 'package:file/file.dart';
import 'package:zora/ast/route_traverser.dart';
import 'package:zora/utils/extensions/directory_extensions.dart';
import 'package:zora/utils/mixins/directories_mixin.dart';
import 'package:zora_construct/zora_construct.dart';

class RoutesHandler with DirectoriesMixin {
  RoutesHandler({
    required this.fs,
    required this.rootPath,
  });

  final FileSystem fs;
  final String rootPath;

  Future<List<MetaRoute>> parse() async {
    final root = await rootOf(rootPath);

    final routesDir = await root.getRoutes();

    if (routesDir == null || !await routesDir.exists()) {
      return [];
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

    return routes;
  }
}
