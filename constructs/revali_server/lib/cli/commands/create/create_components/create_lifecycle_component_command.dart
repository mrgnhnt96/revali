import 'package:change_case/change_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_a_component_command.dart';

class CreateLifecycleComponentCommand extends CreateAComponentCommand {
  CreateLifecycleComponentCommand({
    required super.fs,
    required super.logger,
  }) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the lifecycle component',
      valueHelp: 'name',
    );
  }

  @override
  String get description => 'creates a new lifecycle component';

  @override
  String get name => 'lifecycle Component';

  @override
  String get fileName => '${_name.toSnakeCase()}.dart';

  @override
  String get directory => config.createPaths.lifecycleComponent;

  String _name = '';
  void namePrompt() {
    var name = argResults?['name'] as String?;

    while (name == null || name.isEmpty) {
      name = logger.prompt(
        "What is the name of the ${green.wrap("Lifecycle Component")}?",
      );
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

class ${_name.toPascalCase()} implements LifecycleComponent {
  const ${_name.toPascalCase()}();

  GuardResult guard() {
    // TODO: implement guard
    throw UnimplementedError();
  }

  MiddlewareResult middleware() {
    // TODO: implement middleware
    throw UnimplementedError();
  }

  InterceptorPreResult preInterceptor() {
    // TODO: implement preInterceptor
    throw UnimplementedError();
  }

  InterceptorPostResult postInterceptor() {
    // TODO: implement postInterceptor
    throw UnimplementedError();
  }

  ExceptionCatcherResult<Exception> exceptionCatcher() {
    // TODO: implement exceptionCatcher
    throw UnimplementedError();
  }
}
''';
}
