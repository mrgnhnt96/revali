import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';

/// Builds the argument list the outer `revali` CLI hands to the construct
/// runner running inside the generated entrypoint.
///
/// Only the flags in [forwardedFlags] are emitted, rebuilt from parsed
/// results. Outer-only flags cannot leak through — they are simply not in the
/// list — which is what makes `--cert=a.pem` safe. `--root` is not forwarded
/// here either; `ConstructEntrypointHandler` appends it itself.
mixin ConstructRunnerArgs on Command<int> {
  Logger get logger;

  /// The flags the inner construct runner declares for this command.
  List<ConstructFlag> get forwardedFlags;

  List<String> get constructRunnerArgs {
    final results = argResults!;
    final args = <String>[name];

    for (final flag in forwardedFlags) {
      flag.forward(results, args);
    }

    // Everything after `--` belongs to the server, not to us.
    if (results.rest.isNotEmpty) {
      args
        ..add('--')
        ..addAll(results.rest);
    }

    logger.detail('Construct Args: $args');

    return args;
  }
}
