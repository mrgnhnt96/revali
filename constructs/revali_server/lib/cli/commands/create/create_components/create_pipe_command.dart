import 'package:change_case/change_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_a_component_command.dart';

class CreatePipeCommand extends CreateAComponentCommand {
  CreatePipeCommand({required super.fs, required super.logger}) {
    argParser
      ..addOption(
        'return-type',
        abbr: 'r',
        help: 'The return type of the pipe',
        valueHelp: 'return-type',
      )
      ..addOption(
        'input-type',
        abbr: 'i',
        help: 'The input type of the pipe',
        valueHelp: 'input-type',
      );
  }

  @override
  String get description => 'creates a new pipe';

  @override
  String get name => 'pipe';

  @override
  String get fileName => '${_returnType.toSnakeCase()}_pipe.dart';

  @override
  String get directory => config.createPaths.pipe;

  String _returnType = '';
  void returnTypePrompt() {
    var returnType = argResults?['return-type'] as String?;

    while (returnType == null || returnType.isEmpty) {
      returnType = logger.prompt(
        "What is ${green.wrap("pipe's")} "
        "the ${yellow.wrap('return type')}?",
      );
    }

    _returnType = returnType.trim();
  }

  String _inputType = '';
  void inputTypePrompt() {
    var inputType = argResults?['input-type'] as String?;

    const other = 'Other';
    const defaultInputs = ['String', 'Map<String, dynamic>', other];

    while (inputType == null || inputType.isEmpty) {
      final result = logger.chooseOne(
        "What is ${green.wrap("pipe's")} "
        "the ${yellow.wrap('input type')}?",
        choices: defaultInputs,
      );

      if (result == other) {
        // clears previous line
        logger.write('\u001b[1A\u001b[2K');

        inputType = logger.prompt(
          "What is ${green.wrap("pipe's")} "
          "the ${yellow.wrap('input type')}?",
        );
      } else {
        inputType = result;
      }
    }

    _inputType = switch (inputType) {
      _ when defaultInputs.contains(inputType) => inputType,
      _ => inputType.trim().toPascalCase(),
    };
  }

  @override
  void prompt() {
    inputTypePrompt();
    returnTypePrompt();
  }

  @override
  String content() {
    final pascal = _returnType.toPascalCase();
    final returnType = switch (_returnType) {
      'bool' => 'bool',
      'int' => 'int',
      'double' => 'double',
      _ => pascal.toPascalCase(),
    };
    return '''
import 'dart:async';

import 'package:revali_router/revali_router.dart';

// Learn more about Pipes at https://www.revali.dev/constructs/revali_server/core/pipes
class ${pascal}Pipe implements Pipe<$_inputType, $returnType> {
  const ${pascal}Pipe();

  @override
  Future<$returnType> transform($_inputType value, PipeContext context) async {
    // TODO: implement transform
    throw UnimplementedError();
  }
}
''';
  }
}
