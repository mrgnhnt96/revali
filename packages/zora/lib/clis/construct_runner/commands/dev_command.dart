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

    Future<MetaServer> codeGenerator() async {
      final server = await routesHandler.parse();

      await generate(
        root: root,
        server: server,
        zoraConfig: zoraConfig ??= ZoraYaml.none(),
      );

      return server;
    }

    final serverHandler = VMServiceHandler(
      root: root,
      serverFile: (await root.getZoraFile(ServerFile.fileName)).path,
      codeGenerator: codeGenerator,
      logger: logger,
    );

    final zora = await root.getZora();
    if (await zora.exists()) {
      await zora.delete(recursive: true);
    }

    await serverHandler.start();
    return await serverHandler.exitCode;
  }

  Future<void> generate({
    required Directory root,
    required MetaServer server,
    required ZoraYaml zoraConfig,
  }) async {
    for (final maker in constructs) {
      final constructConfig = zoraConfig.configFor(maker);

      await _generateConstruct(
        maker,
        constructConfig,
        server,
        root,
      );
    }
  }

  Future<void> _generateConstruct(
    ConstructMaker maker,
    ZoraConstructConfig config,
    MetaServer server,
    Directory root,
  ) async {
    logger.detail('Constructing ${maker.name}...');

    if (!config.enabled) {
      if (maker.isServer) {
        logger.warn(
            '${config.name} cannot be disabled, because it is the $ServerConstruct');
      } else {
        logger.detail('skipping ${config.name}');
        return;
      }
    }

    final options = config.constructOptions;

    final construct = maker.maker(options);

    if (maker.isServer) {
      if (construct is! ServerConstruct) {
        throw Exception(
          'Invalid type for router! ${construct.runtimeType} '
          'must be of type $ServerConstruct',
        );
      }

      await _generateServerConstruct(construct, server, root);
      return;
    }
  }

  Future<void> _generateServerConstruct(
    ServerConstruct construct,
    MetaServer server,
    Directory root,
  ) async {
    final result = construct.generate(server);

    final router = await root.getZoraFile(result.basename);

    if (!await router.exists()) {
      await router.create(recursive: true);
    }

    await router.writeAsString(result.getContent());

    final zora = await root.getZora();

    for (final MapEntry(key: basename, value: content)
        in result.getPartContent()) {
      // ensure that the path is within the zora directory
      final partFile = zora.sanitizedChildFile(basename);

      if (!await partFile.exists()) {
        await partFile.create(recursive: true);
      }

      await partFile.writeAsString(content);
    }
  }
}
