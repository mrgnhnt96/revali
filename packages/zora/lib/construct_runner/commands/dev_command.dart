import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';
import 'package:zora/extensions/directory_extensions.dart';
import 'package:zora/handlers/routes_handler.dart';
import 'package:zora/hot_reload/vm_service_runner.dart';
import 'package:zora/mixins/directories_mixin.dart';
import 'package:zora_construct/zora_construct.dart';

class DevCommand extends Command<int> with DirectoriesMixin {
  DevCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    RoutesHandler? routesHandler,
  }) : routesHandler = routesHandler ??
            RoutesHandler(
              fs: fs,
              rootPath: rootPath,
            );

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

    final routes = await routesHandler.parse();

    final constructYamlFile = root.childFile('zora.yaml');
    ZoraYaml? zoraConfig;
    if (await constructYamlFile.exists()) {
      final yamlContent = await constructYamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as YamlMap?;

      try {
        if (yaml != null) {
          // TODO(MRGNHNT): add checked: true during parse
          zoraConfig = ZoraYaml.fromJson(Map<String, dynamic>.from(yaml.value));
        }
      } catch (_) {
        print('Failed to parse zora.yaml');
      }
    }

    Future<void> codeGen() async {
      await generate(
        root: root,
        routes: routes,
        zoraConfig: zoraConfig ??= ZoraYaml.none(),
      );
    }

    final serverRunner = VMServiceRunner(
      root: root,
      serverFile: (await root.getZoraFile('server.dart')).path,
      codeGen: codeGen,
    );

    await serverRunner.start();
    return await serverRunner.exitCode;
  }

  Future<void> generate({
    required Directory root,
    required List<MetaRoute> routes,
    required ZoraYaml zoraConfig,
  }) async {
    for (final maker in constructs) {
      final constructConfig = zoraConfig.configFor(maker);

      if (!constructConfig.enabled) {
        if (maker.isRouter) {
          print(
              '${constructConfig.name} cannot be disabled, because it is the router construct');
        } else {
          print('skipping ${constructConfig.name}');
          continue;
        }
      }

      final options = constructConfig.constructOptions;

      final construct = maker.maker(options);

      if (maker.isRouter) {
        if (construct is! RouterConstruct) {
          throw Exception(
            'Invalid type for router! ${construct.runtimeType} '
            'must be of type $RouterConstruct',
          );
        }

        final result = construct.generate(routes);

        final router = await root.getZoraFile('server.dart');

        if (!await router.exists()) {
          await router.create(recursive: true);
        }

        await router.writeAsString(result);
        continue;
      }
    }
  }
}
