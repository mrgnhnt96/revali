import 'package:args/command_runner.dart';
import 'package:zora/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> {
  DevCommand({
    required ConstructEntrypointHandler generator,
  }) : _generator = generator {
    argParser
      ..addOption(
        'port',
        abbr: 'p',
        help: 'The port to run the server on',
        defaultsTo: '8080',
      )
      ..addFlag(
        'recompile',
        help:
            'Re-compiles the construct kernel. Needed to sync changes for a local construct.',
        negatable: false,
        defaultsTo: false,
      );
  }

  final ConstructEntrypointHandler _generator;

  @override
  String get name => 'dev';

  @override
  String get description => 'Starts the development server';

  @override
  Future<int> run() async {
    final recompile = argResults!['recompile'] as bool;

    await _generator.generate(recompile: recompile);
    await _generator.run(['dev']);

    return 0;
  }
}
