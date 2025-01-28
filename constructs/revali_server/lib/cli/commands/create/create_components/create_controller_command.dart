import 'package:change_case/change_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_a_component_command.dart';

class CreateControllerCommand extends CreateAComponentCommand {
  CreateControllerCommand({
    required super.fs,
    required super.logger,
  }) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the controller',
      valueHelp: 'name',
    );
  }

  @override
  String get description => 'creates a new controller';

  @override
  String get name => 'controller';

  @override
  String get fileName => '${_name.toSnakeCase()}_controller.dart';

  @override
  String get directory => config.createPaths.controller;

  String _name = '';
  void namePrompt() {
    var name = argResults?['name'] as String?;

    while (name == null || name.isEmpty) {
      name =
          logger.prompt("What's the name of the ${green.wrap('controller')}?");
    }

    _name = name.trim();
  }

  @override
  void prompt() {
    namePrompt();
  }

  @override
  String content() => '''
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('${name.toPathCase()}')
class ${name.toPascalCase()}Controller {
  const ${name.toPascalCase()}Controller();

  @Get()
  String handle() {
    return 'Hello world!';
  }
}
''';
}
