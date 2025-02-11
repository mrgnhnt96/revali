import 'package:change_case/change_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_a_component_command.dart';

class CreateAppCommand extends CreateAComponentCommand {
  CreateAppCommand({
    required super.fs,
    required super.logger,
  }) {
    argParser.addOption(
      'flavor',
      abbr: 'n',
      help: 'The flavor of the app',
      valueHelp: 'flavor',
    );
  }

  @override
  String get description => 'creates a new app';

  @override
  String get name => 'app';

  String? get flavorName => argResults?['flavor'] as String?;

  @override
  String get directory => config.createPaths.app;

  @override
  String get fileName => '${_flavor.toSnakeCase()}_app.dart';

  String _flavor = '';

  @override
  void prompt() {
    flavorPrompt();
  }

  void flavorPrompt() {
    var flavor = flavorName;

    while (flavor == null || flavor.trim().isEmpty) {
      flavor = logger.prompt("What's the flavor of the ${green.wrap('app')}?");
    }

    _flavor = flavor.trim();
  }

  @override
  String content() => '''
import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://www.revali.dev/revali/app-configuration/overview
@App(flavor: '$_flavor')
final class ${_flavor.toPascalCase()}App extends AppConfig {
  const ${_flavor.toPascalCase()}App() : super(host: 'localhost', port: 8080);
}
''';
}
