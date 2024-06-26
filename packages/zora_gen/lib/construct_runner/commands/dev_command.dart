import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/src/interface/file_system.dart';
import 'package:yaml/yaml.dart';
import 'package:zora_gen/extensions/directory_extensions.dart';
import 'package:zora_gen/mixins/directories_mixin.dart';
import 'package:zora_gen/parsers/routes_handler.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class DevCommand extends Command<int> with DirectoriesMixin {
  DevCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    RoutesHandler? routesHandler,
  }) : routesHandler = routesHandler ?? RoutesHandler(fs: fs);

  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final String rootPath;
  @override
  final FileSystem fs;

  @override
  String get description => 'Starts the development server';

  @override
  String get name => 'dev';

  @override
  Future<int>? run() async {
    final root = await rootOf(rootPath);

    final routes = await root.getRoutes();

    final constructYamlFile = root.childFile('zora.yaml');
    final yamlContent =
        loadYaml(await constructYamlFile.readAsString()) as YamlMap;

    final config =
        ZoraYaml.fromJson(Map<String, dynamic>.from(yamlContent.value));

    return 0;
  }
}
