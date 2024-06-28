import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';
import 'package:zora/handlers/routes_handler.dart';
import 'package:zora/handlers/vm_service_handler.dart';
import 'package:zora/utils/extensions/directory_extensions.dart';
import 'package:zora/utils/mixins/directories_mixin.dart';
import 'package:zora_construct/zora_construct.dart';

class DevCommand extends Command<int> with DirectoriesMixin {
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
            );

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

  @override
  Future<int>? run() async {
    final root = await rootOf(rootPath);

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
        logger.err('Failed to parse zora.yaml, using default configuration.');
      }
    }

    Future<List<MetaRoute>> codeGenerator() async {
      final routes = await routesHandler.parse();

      await generate(
        root: root,
        routes: routes,
        zoraConfig: zoraConfig ??= ZoraYaml.none(),
      );

      return routes;
    }

    final serverHandler = VMServiceHandler(
      root: root,
      serverFile: (await root.getZoraFile('server.dart')).path,
      codeGenerator: codeGenerator,
      logger: logger,
    );

    await serverHandler.start();
    return await serverHandler.exitCode;
  }

  Future<void> generate({
    required Directory root,
    required List<MetaRoute> routes,
    required ZoraYaml zoraConfig,
  }) async {
    for (final maker in constructs) {
      logger.detail('Constructing ${maker.name}...');

      final constructConfig = zoraConfig.configFor(maker);

      if (!constructConfig.enabled) {
        if (maker.isServer) {
          logger.warn(
              '${constructConfig.name} cannot be disabled, because it is the $ServerConstruct');
        } else {
          logger.detail('skipping ${constructConfig.name}');
          continue;
        }
      }

      final options = constructConfig.constructOptions;

      final construct = maker.maker(options);

      if (maker.isServer) {
        if (construct is! ServerConstruct) {
          throw Exception(
            'Invalid type for router! ${construct.runtimeType} '
            'must be of type $ServerConstruct',
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
