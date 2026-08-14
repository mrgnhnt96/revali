import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/services/service_discovery.dart';

/// Lists the Revali services in a repository.
class ServicesCommand extends Command<int> {
  ServicesCommand({required this.logger, required this.fs}) {
    argParser
      ..addOption(
        'root',
        help: 'Directory to search from. Defaults to the working directory.',
        valueHelp: 'path',
      )
      ..addFlag(
        'paths',
        help: 'Print only paths, one per line, for scripting',
        negatable: false,
      );
  }

  final Logger logger;
  final FileSystem fs;

  @override
  String get name => 'services';

  @override
  String get description => 'List the Revali services in this repository';

  @override
  Future<int> run() async {
    final rootPath = argResults?['root'] as String? ?? fs.currentDirectory.path;
    final root = fs.directory(rootPath);

    if (!root.existsSync()) {
      logger.err('No such directory: $rootPath');

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

    if (argResults?['paths'] as bool? ?? false) {
      for (final service in services) {
        io.stdout.writeln(service.relativePath);
      }

      return 0;
    }

    logger.info('${services.length} service(s)\n');

    final width = services
        .map((s) => s.name.length)
        .reduce((a, b) => a > b ? a : b);

    for (final service in services) {
      final built = service.hasDockerfile ? '' : '  (no Dockerfile yet)';

      logger.info(
        '  ${service.name.padRight(width)}  ${service.relativePath}$built',
      );
    }

    return 0;
  }
}
