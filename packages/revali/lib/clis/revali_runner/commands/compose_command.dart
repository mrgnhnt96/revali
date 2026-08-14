import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/services/compose_maker.dart';
import 'package:revali/services/service_discovery.dart';

/// Generates a `docker-compose.yaml` covering every service in a repository.
class ComposeCommand extends Command<int> {
  ComposeCommand({required this.logger, required this.fs}) {
    argParser
      ..addOption(
        'root',
        help: 'Directory to search from. Defaults to the working directory.',
        valueHelp: 'path',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Where to write. Defaults to docker-compose.yaml at the root.',
        valueHelp: 'path',
      )
      ..addOption(
        'base-port',
        help: 'First host port to assign; services take one each in order.',
        valueHelp: 'port',
        defaultsTo: '8080',
      )
      ..addFlag(
        'stdout',
        help: 'Print instead of writing a file',
        negatable: false,
      );
  }

  final Logger logger;
  final FileSystem fs;

  @override
  String get name => 'compose';

  @override
  String get description =>
      'Generate a docker-compose.yaml for every service in this repository';

  @override
  Future<int> run() async {
    final rootPath = argResults?['root'] as String? ?? fs.currentDirectory.path;
    final root = fs.directory(rootPath);

    if (!root.existsSync()) {
      logger.err('No such directory: $rootPath');

      return 1;
    }

    final basePort = int.tryParse(argResults?['base-port'] as String? ?? '');
    if (basePort == null) {
      logger.err('--base-port must be a number');

      return 1;
    }

    final services = const ServiceDiscovery().find(root);

    if (services.isEmpty) {
      logger.err(
        'No Revali services found under $rootPath.\n'
        'A service is a package with a routes/ directory that depends on '
        'revali_router.',
      );

      return 1;
    }

    final content = composeFile(services, basePort: basePort);

    if (argResults?['stdout'] as bool? ?? false) {
      io.stdout.write(content);

      return 0;
    }

    final outputPath =
        argResults?['output'] as String? ??
        p.join(root.path, 'docker-compose.yaml');
    final output = fs.file(outputPath);

    output.parent.createSync(recursive: true);
    output.writeAsStringSync(content);

    logger.success('Wrote ${services.length} service(s) to $outputPath');

    final missing = services.where((s) => !s.hasDockerfile).toList();
    if (missing.isNotEmpty) {
      // Worth saying out loud: `docker compose up` would fail on these, and
      // the reason is in a comment in a generated file nobody reads.
      final paths = missing.map((s) => s.relativePath).join(', ');

      logger.warn(
        '${missing.length} service(s) have no Dockerfile yet. '
        'Run `revali build` in: $paths',
      );
    }

    return 0;
  }
}
