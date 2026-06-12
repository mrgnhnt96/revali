import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:revali/ast/analyzer/units.dart';
import 'package:revali/ast/file_traverser.dart';
import 'package:revali_construct/revali_construct.dart';

class SwaggerE2eHelper {
  SwaggerE2eHelper._({required this.fixtureRoot, required this.server});

  static Future<SwaggerE2eHelper> create() async {
    final fixtureRoot = p.normalize(
      p.join(Directory.current.path, 'test', 'fixtures', 'sample_app'),
    );

    final pubGetResult = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: fixtureRoot);

    if (pubGetResult.exitCode != 0) {
      throw StateError(
        'dart pub get failed in $fixtureRoot:\n${pubGetResult.stderr}',
      );
    }

    final routesDir = p.join(fixtureRoot, 'routes');
    final collection = AnalysisContextCollection(includedPaths: [fixtureRoot]);
    const traverser = FileTraverser(LocalFileSystem());

    final controllerFiles = Directory(routesDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_controller.dart'))
        .toList();

    final routes = <MetaRoute>[];
    for (final file in controllerFiles) {
      final path = p.normalize(file.absolute.path);
      final context = collection.contextFor(path);
      final units = Units(context: context, path: path);
      if (await traverser.parseRoute(units) case final route?) {
        routes.add(route);
      }
    }

    final server = MetaServer(routes: routes, apps: const [], public: const []);

    return SwaggerE2eHelper._(fixtureRoot: fixtureRoot, server: server);
  }

  final String fixtureRoot;
  final MetaServer server;
}
