import 'package:change_case/change_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_a_component_command.dart';

class CreateObserverCommand extends CreateAComponentCommand {
  CreateObserverCommand({required super.fs, required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the lifecycle component',
      valueHelp: 'name',
    );
  }

  @override
  String get description => 'creates a new observer';

  @override
  String get name => 'observer';

  @override
  String get fileName => '${_name.toSnakeCase()}_observer.dart';

  @override
  String get directory => config.createPaths.observer;

  String _name = '';
  void namePrompt() {
    var name = argResults?['name'] as String?;

    while (name == null || name.isEmpty) {
      name = logger.prompt(
        "What is the name of the ${green.wrap("Observer")}?",
      );
    }

    _name = name.trim();
  }

  @override
  void prompt() {
    namePrompt();
  }

  @override
  String content() =>
      '''
import 'package:revali_router/revali_router.dart';

// Learn more about Observers at https://www.revali.dev/constructs/revali_server/lifecycle-components/observer
class ${_name.toPascalCase()}Observer implements Observer {
  const ${_name.toPascalCase()}Observer();

  @override
  Future<void> see(
    ReadOnlyRequest request,
    Future<ReadOnlyResponse> response,
  ) async {
    // TODO: implement see
    throw UnimplementedError();
  }
}
''';
}
