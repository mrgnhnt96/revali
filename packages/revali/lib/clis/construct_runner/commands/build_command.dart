import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/clis/construct_runner/commands/mixins/dart_defines_mixin.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali/utils/ticked_progress.dart';
import 'package:revali_construct/revali_construct.dart';

class BuildCommand extends Command<int>
    with DirectoriesMixin, DartDefinesMixin {
  BuildCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    required this.logger,
    required Analyzer analyzer,
    RoutesHandler? routesHandler,
  }) : routesHandler =
           routesHandler ??
           RoutesHandler(analyzer: analyzer, fs: fs, rootPath: rootPath) {
    sharedBuildFlags.declareAll(argParser);
  }

  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final String rootPath;
  @override
  final FileSystem fs;
  final Logger logger;

  @override
  String get name => 'build';

  @override
  String get description => 'Compiles the server';

  late final flavor = argResults?['flavor'] as String?;
  late final release = argResults?['release'] as bool? ?? true;
  late final profile = argResults?['profile'] as bool? ?? false;

  /// The single phase `--type` selected, or null for both.
  late final type = switch (argResults?['type'] as String?) {
    final name? => GenerateConstructType.values.byName(name),
    null => null,
  };

  /// The phases to run, constructs first.
  ///
  /// Order is load-bearing rather than stylistic: the build phase compiles
  /// `server/server.dart`, and the constructs phase is what writes it.
  List<GenerateConstructType> get _phases => switch (type) {
    final phase? => [phase],
    null => const [
      GenerateConstructType.constructs,
      GenerateConstructType.build,
    ],
  };

  @override
  Future<int> run() async {
    final root = await rootOf(rootPath);

    final make = switch ((profile, release)) {
      (true, _) => ConstructGenerator.profile,
      _ => ConstructGenerator.release,
    };

    final progress = TickedProgress('Building', level: logger.level);

    // A generator per phase. `generateConstructType` is final, and each phase
    // stages and promotes its own outputs, so they cannot share an instance.
    for (final phase in _phases) {
      final generator = make(
        flavor: flavor,
        routesHandler: routesHandler,
        makers: constructs,
        logger: logger,
        fs: fs,
        rootPath: root.path,
        dartDefines: defines,
        generateConstructType: phase,
      );

      await generator.generate(progress.update);
    }

    progress.complete('Build succeeded');

    return 0;
  }
}
