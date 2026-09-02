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

    // Nothing below this point applies to a run that stops after generating.
    if (profile || generateOnly) {
      return _generateOnce(generator);
    }

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

  /// Generates once, and reports whether the project it generated from
  /// actually analyses.
  ///
  /// This used to `return 0` unconditionally. `dart run revali dev
  /// --generate-only` emitted a server against source that does not even
  /// parse and still exited 0, so every caller that reads the exit code as the
  /// verdict -- scripts/verify_generated_suites.sh, CI, the pre-push hook --
  /// took "the generator produced a server" to mean "the project is sound".
  /// The failure surfaced much later, as a compile error in whatever consumed
  /// the output, at which point it no longer points at the generator.
  ///
  /// The check runs BEFORE generating, which is what the watch path already
  /// does on every reload and file change (see `checkForErrors` in
  /// vm_service_handler.dart). Output written from source that does not
  /// analyse is not output anyone should act on, and it is the same reason
  /// `_generate` discards its staging directory rather than publishing a
  /// half-built one: leaving the previous generation in place is the more
  /// honest state on disk.
  Future<int> _generateOnce(ConstructGenerator generator) async {
    final errors = await routesHandler.errors();

    if (errors.isNotEmpty) {
      final count = errors.fold(0, (sum, e) => sum + e.$2.length);

      logger.err('Found $count ${count == 1 ? 'error' : 'errors'}');
      for (final (path, errors) in errors) {
        logger.write('\n${yellow.wrap(path)}\n');
        for (final error in errors) {
          logger.write('${red.wrap('  -')} ${error.message}\n');
        }
      }
      logger.write('\n');

      return 1;
    }

    final progress = TickedProgress(
      'Generating server code',
      level: logger.level,
    );

    await generator.generate(logger.delayed);

    progress.complete('Generated server code');

    return 0;
  }
}
