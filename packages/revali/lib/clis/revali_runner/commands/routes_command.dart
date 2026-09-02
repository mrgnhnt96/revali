import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:revali/server/contract/contract_check.dart';

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
      ..addFlag('json', help: 'Print raw routes.json', negatable: false)
      ..addOption(
        'check',
        help:
            'Compare the current manifest against a pinned routes.json and '
            'exit non-zero on breaking changes',
        valueHelp: 'path',
      );
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
          final code = await _generator.run(const ['dev', '--generate-only']);

          // Reading the manifest after a failed generation reports on
          // whatever the previous run left behind, which is the stale answer
          // this command exists to avoid.
          if (code != 0) {
            return code;
          }
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

    final pinnedPath = argResults?['check'] as String?;
    if (pinnedPath != null) {
      return _check(pinnedPath, raw);
    }

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

  /// Compares the current manifest against a pinned one.
  ///
  /// Exits 1 when a consumer that built against the pin could now break, so
  /// this is usable as a CI gate.
  int _check(String pinnedPath, String currentRaw) {
    final pinned = fs.file(pinnedPath);

    if (!pinned.existsSync()) {
      logger.err('No pinned manifest at $pinnedPath');
      return 1;
    }

    final ContractReport report;
    try {
      report = checkContract(
        jsonDecode(pinned.readAsStringSync()) as Map<String, dynamic>,
        jsonDecode(currentRaw) as Map<String, dynamic>,
      );
    } catch (e) {
      logger.err('Could not compare manifests: $e');
      return 1;
    }

    for (final change in report.compatible) {
      logger.info('  compatible  $change');
    }
    for (final change in report.breaking) {
      logger.err('  BREAKING    $change');
    }

    if (report.changes.isEmpty) {
      logger.success('No contract changes against $pinnedPath');
      return 0;
    }

    if (!report.hasBreaking) {
      logger.success(
        '\n${report.compatible.length} compatible change(s), none breaking',
      );
      return 0;
    }

    logger.err('\n${report.breaking.length} breaking change(s)');
    return 1;
  }
}
