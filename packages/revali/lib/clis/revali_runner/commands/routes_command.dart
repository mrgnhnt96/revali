import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class RoutesCommand extends Command<int> {
  RoutesCommand({
    required this.logger,
    required this.fs,
    required ConstructEntrypointHandler generator,
  }) : _generator = generator {
    argParser
      ..addFlag(
        'generate',
        abbr: 'g',
        help: 'Run generate-only before reading the manifest',
        negatable: false,
      )
      ..addFlag('json', help: 'Print raw routes.json', negatable: false);
  }

  final Logger logger;
  final FileSystem fs;
  final ConstructEntrypointHandler _generator;

  @override
  String get name => 'routes';

  @override
  String get description =>
      'List generated routes from .revali/server/routes.json';

  @override
  Future<int> run() async {
    final root = await _generator.rootOf(_generator.initialDirectory);

    if (argResults?['generate'] as bool? ?? false) {
      try {
        final shouldRun = await _generator.generate();
        if (shouldRun) {
          await _generator.run(const ['dev', '--generate-only']);
        }
      } catch (e) {
        logger.err('Failed to generate: $e');
        return 1;
      }
    }

    final manifest = fs.file(
      p.join(root.path, '.revali', 'server', 'routes.json'),
    );

    if (!manifest.existsSync()) {
      logger.err(
        'No routes.json at ${manifest.path}. '
        'Run `dart run revali routes --generate` or `dart run revali dev '
        '--generate-only` first.',
      );
      return 1;
    }

    final raw = await manifest.readAsString();
    if (argResults?['json'] as bool? ?? false) {
      io.stdout.writeln(raw.trimRight());
      return 0;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final routes = (decoded['routes'] as List<dynamic>?) ?? const [];
    final prefix = decoded['prefix'] ?? 'api';

    logger.info('prefix: /$prefix  (${routes.length} routes)\n');
    for (final entry in routes) {
      final route = entry as Map<String, dynamic>;
      final method = (route['method'] as String? ?? '?').padRight(7);
      final path = route['path'] as String? ?? '';
      final handler = route['handler'] as String? ?? '';
      final controller = route['controller'] as String? ?? '';
      logger.info('$method $path  →  $controller.$handler');
    }

    return 0;
  }
}
