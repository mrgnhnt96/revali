import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/clis/construct_runner/commands/mixins/dart_defines_mixin.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/handlers/vm_service_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali/utils/ticked_progress.dart';
import 'package:revali_construct/revali_construct.dart';

class DevCommand extends Command<int> with DirectoriesMixin, DartDefinesMixin {
  DevCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    required this.logger,
    required this.analyzer,
    RoutesHandler? routesHandler,
  }) : routesHandler =
           routesHandler ??
           RoutesHandler(analyzer: analyzer, fs: fs, rootPath: rootPath) {
    sharedDevFlags.declareAll(argParser);
  }

  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final String rootPath;
  @override
  final FileSystem fs;
  final Logger logger;
  final Analyzer analyzer;

  @override
  String get description => 'Starts the development server';

  @override
  String get name => 'dev';

  late final flavor = argResults?['flavor'] as String?;
  late final debug = argResults?['debug'] as bool? ?? false;
  late final release = argResults?['release'] as bool? ?? false;
  late final profile = argResults?['profile'] as bool? ?? false;
  late final generateOnly = argResults?['generate-only'] as bool? ?? false;
  late final dartVmServicePort = argResults?['dart-vm-service-port'] as String;

  @override
  Future<int>? run() async {
    final runInRelease = release && !debug;

    final mode = switch ((debug, profile, release)) {
      (true, _, _) => Mode.debug,
      (_, true, _) => Mode.profile,
      (_, _, true) => Mode.release,
      _ => Mode.debug,
    };

    final generator = ConstructGenerator(
      flavor: flavor,
      routesHandler: routesHandler,
      makers: constructs,
      logger: logger,
      fs: fs,
      rootPath: rootPath,
      mode: mode,
    );

    final root = await generator.root;
    final revaliConfig = await generator.revaliConfig;

    final hotReloadExclude = [
      ...?revaliConfig.hotReload?.exclude.map((path) {
        if (p.isAbsolute(path)) {
          return p.normalize(path);
        }

        return p.normalize(p.join(root.path, path));
      }),
      p.normalize(p.join(root.path, '.revali.staging')),
      p.normalize(p.join(root.path, '.revali')),
      // Tooling / scripts should not bounce the server.
      p.normalize(p.join(root.path, 'bin')),
      p.normalize(p.join(root.path, 'test')),
      p.normalize(p.join(root.path, 'tool')),
    ];

    logger.detail('Hot reload exclude: $hotReloadExclude');

    if (profile || generateOnly) {
      final progress = TickedProgress(
        'Generating server code',
        level: logger.level,
      );

      await generator.generate(logger.delayed);

      progress.complete('Generated server code');

      return 0;
    }

    final serverHandler = VMServiceHandler(
      root: root,
      serverFile: (await root.getServer())
          .childFile(ServerFile.nameWithExtension)
          .path,
      codeGenerator: generator.generate,
      logger: logger,
      canHotReload: !runInRelease,
      dartDefine: defines,
      dartVmServicePort: dartVmServicePort,
      serverArgs: argResults?.rest ?? [],
      mode: mode,
      onFilesChange: analyzer.refresh,
      onFileRemove: analyzer.remove,
      errors: generator.getErrors,
      getDependencyDirectories: analyzer.getPathDependencyDirectories,
      hotReloadExclude: hotReloadExclude,
    );

    await serverHandler.start(enableHotReload: !runInRelease);
    return serverHandler.exitCode;
  }
}
