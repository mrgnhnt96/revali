import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

mixin ConstructRunnerArgs on Command<int> {
  Logger get logger;

  List<String> get constructRunnerArgs {
    final argResults = this.argResults!;

    final argsToPass = <String>[name];

    final flavor = argResults['flavor'] as String?;
    if (flavor != null && flavor.isNotEmpty) {
      argsToPass.addAll(['--flavor', flavor]);
    }

    const ignore = {'--recompile'};

    var skipNext = false;
    for (final entry in argResults.arguments) {
      if (skipNext) {
        skipNext = false;
        continue;
      }

      if (entry == '--flavor' || entry == '-f') {
        skipNext = true;
        continue;
      }

      if (ignore.contains(entry)) {
        continue;
      }

      argsToPass.add(entry);
    }

    logger.detail('Construct Args: $argsToPass');

    return argsToPass;
  }
}
