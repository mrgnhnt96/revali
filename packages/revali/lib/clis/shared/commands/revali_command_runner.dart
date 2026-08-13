import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Shared behavior for the outer `revali` CLI and the inner construct runner.
///
/// Both expose the same hidden verbosity flags and both need the logger
/// flushed once a command finishes, so that lives here rather than being
/// copied into each runner.
abstract class RevaliCommandRunner extends CommandRunner<int> {
  RevaliCommandRunner(
    super.executableName,
    super.description, {
    required this.logger,
  }) {
    argParser
      ..addFlag('loud', help: 'Prints detailed output', hide: true)
      ..addFlag(
        'quiet',
        help: 'Limits output to important information only',
        hide: true,
      );
  }

  final Logger logger;

  @override
  Future<int> run(Iterable<String> args) async => await super.run(args) ?? 0;

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    final result = await super.runCommand(topLevelResults);

    logger.flush();

    return result ?? 0;
  }
}
