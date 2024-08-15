import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

mixin ConstructRunnerArgs on Command<int> {
  Logger get logger;

  List<String> get constructRunnerArgs {
    final argResults = this.argResults!;

    final argsToPass = <String>[];

    const ignore = {'--recompile'};

    for (final entry in [name, ...argResults.arguments]) {
      if (ignore.contains(entry)) {
        continue;
      }

      argsToPass.add(entry);
    }

    logger.detail('Construct Args: $argsToPass');

    return argsToPass;
  }
}
