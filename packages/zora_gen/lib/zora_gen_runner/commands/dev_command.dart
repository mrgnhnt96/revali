import 'package:args/command_runner.dart';
import 'package:zora_gen/generators/entrypoint_generator.dart';

class DevCommand extends Command<int> {
  DevCommand({
    required EntrypointGenerator generator,
  }) : _generator = generator;

  final EntrypointGenerator _generator;

  @override
  String get name => 'dev';

  @override
  String get description => 'Starts the development server';

  @override
  Future<int> run() async {
    await _generator.generate();
    await _generator.run(['dev']);

    return 0;
  }
}
