import 'package:analyzer/error/error.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/ast/file_traverser.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';

class RoutesHandler with DirectoriesMixin {
  RoutesHandler({
    required this.fs,
    required this.rootPath,
    required this.analyzer,
  });

  @override
  final FileSystem fs;
  final String rootPath;
  final Analyzer analyzer;

  Future<List<(String, List<AnalysisError>)>> errors() async {
    await analyzer.initialize(root: rootPath);

    final mapped = <String, List<AnalysisError>>{};

    for (final error in await analyzer.errors(rootPath)) {
      final path = fs.path.relative(error.source.fullName);
      mapped.putIfAbsent(path, () => []).add(error);
    }

    return mapped.entries.map((e) => (e.key, e.value)).toList();
  }

  Future<MetaServer> parse() async {
    final root = await rootOf(rootPath);

    await analyzer.initialize(root: rootPath);

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
    Directory root,
  ) async {
    final routesDir = await root.getRoutes();

    if (routesDir == null || !await routesDir.exists()) {
      return (routes: <MetaRoute>[], apps: [MetaAppConfig.defaultConfig()]);
    }

    final files = await analyzer.analyze(routesDir.path);

    final traverser = FileTraverser(fs);

    final routes = <MetaRoute>[];
    final apps = <MetaAppConfig>[];

    for (final entity in files) {
      if (await traverser.parseRoute(entity) case final route?) {
        routes.add(route);
        continue;
      }

      await for (final app in traverser.parseApps(entity)) {
        apps.add(app);
      }
    }

    if (apps.isEmpty) {
      apps.add(MetaAppConfig.defaultConfig());
    }

    return (routes: routes, apps: apps);
  }
}
