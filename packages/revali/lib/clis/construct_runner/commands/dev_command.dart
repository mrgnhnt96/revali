import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/construct_runner/commands/mixins/dart_defines_mixin.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/handlers/vm_service_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';

class DevCommand extends Command<int> with DirectoriesMixin, DartDefinesMixin {
  DevCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    required this.logger,
    RoutesHandler? routesHandler,
  }) : routesHandler = routesHandler ??
            RoutesHandler(
              fs: fs,
              rootPath: rootPath,
            ) {
    argParser
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'The flavor to use for the app (case-sensitive)',
      )
      ..addFlag(
        'release',
        help:
            'Whether to run in release mode. Disabled hot reload and debugger',
      )
      ..addFlag(
        'debug',
        help: 'Whether to run in debug mode. Enables hot reload and debugger',
      )
      ..addOption(
        'dart-vm-service-port',
        help: 'The port to use for the Dart VM service',
        defaultsTo: '8080',
      )
      ..addMultiOption(
        'dart-define',
        help: 'Additional key-value pairs that will be available as constants.',
        valueHelp: 'BASE_URL=https://api.example.com',
      )
      ..addMultiOption(
        'dart-define-from-file',
        help: 'A file containing additional key-value '
            'pairs that will be available as constants.',
        valueHelp: '.env',
      );
  }

  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final String rootPath;
  @override
  final FileSystem fs;
  final Logger logger;

  @override
  String get description => 'Starts the development server';

  @override
  String get name => 'dev';

  late final flavor = argResults?['flavor'] as String?;
  late final debug = argResults?['debug'] as bool? ?? false;
  late final release = argResults?['release'] as bool? ?? false;
  late final dartVmServicePort = argResults?['dart-vm-service-port'] as String;

  @override
  Future<int>? run() async {
    final runInRelease = release && !debug;

    final generator = switch (runInRelease) {
      true => ConstructGenerator.release,
      false => ConstructGenerator.debug,
    }(
      flavor: flavor,
      routesHandler: routesHandler,
      constructs: constructs,
      logger: logger,
      fs: fs,
      rootPath: rootPath,
    );

    final root = await generator.root;

    final serverHandler = VMServiceHandler(
      root: root,
      serverFile: (await root.getRevaliFile(ServerFile.nameWithExtension)).path,
      codeGenerator: generator.generate,
      logger: logger,
      canHotReload: !runInRelease,
      dartDefine: defines,
      dartVmServicePort: dartVmServicePort,
    );

    final revali = await root.getRevali();
    if (await revali.exists()) {
      await revali.delete(recursive: true);
    }

    await serverHandler.start(enableHotReload: !runInRelease);
    return serverHandler.exitCode;
  }
}
