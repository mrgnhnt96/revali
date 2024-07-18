import 'package:file/file.dart';
import 'package:path/path.dart' as p;
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

    final (:routes, :apps) = await _getRoutes(root);

    final publicRoutes = await _getPublic(root);

    return MetaServer(
      routes: routes,
      apps: apps,
      public: publicRoutes,
    );
  }

  Future<List<MetaPublic>> _getPublic(Directory root) async {
    final publicDir = await root.getPublic();

    if (!await publicDir.exists()) {
      return [];
    }

    final files = await publicDir
        .list(
          recursive: true,
          followLinks: false,
        )
        .toList();

    final routes = <MetaPublic>[];

    for (final file in files) {
      if (file is! File) continue;

      final path = p.relative(file.path, from: publicDir.path);

      final route = MetaPublic(path: path);
      routes.add(route);
    }

    return routes;
  }

  Future<({List<MetaRoute> routes, List<MetaAppConfig> apps})> _getRoutes(
      Directory root) async {
    final routesDir = await root.getRoutes();

    if (routesDir == null || !await routesDir.exists()) {
      return (routes: <MetaRoute>[], apps: [MetaAppConfig.defaultConfig()]);
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

      final result = await traverser.parseApps(file).toList();

      if (result.isNotEmpty) {
        apps.addAll(result);
        continue;
      }
    }

    if (apps.isEmpty) {
      apps.add(MetaAppConfig.defaultConfig());
    }

    return (routes: routes, apps: apps);
  }
}
