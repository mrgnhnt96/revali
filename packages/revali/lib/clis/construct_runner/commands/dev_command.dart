import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/handlers/vm_service_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:yaml/yaml.dart';

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
            ) {
    argParser.addOption(
      'flavor',
      abbr: 'f',
      help: 'The flavor to use for the app (case-sensitive)',
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

  @override
  Future<int>? run() async {
    final flavor = argResults?['flavor'] as String?;

    final context = RevaliContext(flavor: flavor);

    final root = await rootOf(rootPath);

    final constructYamlFile = root.childFile('revali.yaml');
    revaliYaml? revaliConfig;
    if (await constructYamlFile.exists()) {
      final yamlContent = await constructYamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as YamlMap?;

      try {
        if (yaml != null) {
          revaliConfig =
              revaliYaml.fromJson(Map<String, dynamic>.from(yaml.value));
        }
      } catch (_) {
        logger.err('Failed to parse revali.yaml, using default configuration.');
      }
    }

    Future<MetaServer> codeGenerator() async {
      final server = await routesHandler.parse();

      await generate(
        root: root,
        context: context,
        server: server,
        revaliConfig: revaliConfig ??= revaliYaml.none(),
      );

      return server;
    }

    final serverHandler = VMServiceHandler(
      root: root,
      serverFile: (await root.getRevaliFile(ServerFile.fileName)).path,
      codeGenerator: codeGenerator,
      logger: logger,
    );

    final revali = await root.getRevali();
    if (await revali.exists()) {
      await revali.delete(recursive: true);
    }

    await serverHandler.start();
    return await serverHandler.exitCode;
  }

  Future<void> generate({
    required Directory root,
    required RevaliContext context,
    required MetaServer server,
    required revaliYaml revaliConfig,
  }) async {
    for (final maker in constructs) {
      final constructConfig = revaliConfig.configFor(maker);

      await _generateConstruct(
        maker,
        constructConfig,
        context,
        server,
        root,
      );
    }
  }

  Future<void> _generateConstruct(
    ConstructMaker maker,
    RevaliConstructConfig config,
    RevaliContext context,
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

      await _generateServerConstruct(construct, context, server, root);
      return;
    }
  }

  Future<void> _generateServerConstruct(
    ServerConstruct construct,
    RevaliContext context,
    MetaServer server,
    Directory root,
  ) async {
    final result = construct.generate(context, server);

    final router = await root.getRevaliFile(result.basename);

    if (!await router.exists()) {
      await router.create(recursive: true);
    }

    await router.writeAsString(result.getContent());

    final revali = await root.getRevali();

    for (final MapEntry(key: basename, value: content)
        in result.getPartContent()) {
      // ensure that the path is within the revali directory
      final partFile = revali.sanitizedChildFile(basename);

      if (!await partFile.exists()) {
        await partFile.create(recursive: true);
      }

      await partFile.writeAsString(content);
    }
  }
}
