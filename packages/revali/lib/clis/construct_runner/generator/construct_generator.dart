import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/models/files/server_directory.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:yaml/yaml.dart';

class ConstructGenerator with DirectoriesMixin {
  ConstructGenerator({
    required this.mode,
    required this.flavor,
    required this.routesHandler,
    required this.constructs,
    required this.logger,
    required this.fs,
    required String rootPath,
  }) : _rootPath = rootPath;
  ConstructGenerator.release({
    required this.flavor,
    required this.routesHandler,
    required this.constructs,
    required this.logger,
    required this.fs,
    required String rootPath,
  })  : mode = Mode.release,
        _rootPath = rootPath;
  ConstructGenerator.debug({
    required this.flavor,
    required this.routesHandler,
    required this.constructs,
    required this.logger,
    required this.fs,
    required String rootPath,
  })  : mode = Mode.debug,
        _rootPath = rootPath;

  final Mode mode;
  final String? flavor;
  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final Logger logger;
  @override
  final FileSystem fs;
  final String _rootPath;

  Directory? _root;
  Future<Directory> get root async {
    if (_root case final root?) {
      return root;
    }

    final root = await rootOf(_rootPath);

    return _root = root;
  }

  RevaliContext get context => RevaliContext(
        flavor: flavor,
        mode: mode,
      );

  Future<void> clean() async {
    final root = await this.root;

    final revali = await root.getRevali();
    if (await revali.exists()) {
      await revali.delete(recursive: true);
    }
  }

  Future<MetaServer?> generate() async {
    final server = await routesHandler.parse();

    final root = await this.root;

    try {
      await _generate(
        root: root,
        context: context,
        server: server,
        revaliConfig: await revaliConfig(),
      );
    } catch (e) {
      logger
        ..delayed(red.wrap('Error occurred while generating constructs'))
        ..delayed(red.wrap('$e'));
      return null;
    }

    return server;
  }

  Future<void> _generate({
    required Directory root,
    required RevaliContext context,
    required MetaServer server,
    required RevaliYaml revaliConfig,
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
          '${config.name} cannot be disabled,'
          ' because it is the $ServerConstruct',
        );
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
    final ServerDirectory(files: [result]) =
        construct.generate(context, server);

    final revali = await root.getRevali();

    final revaliEntities = switch (await revali.exists()) {
      true => await revali.list(recursive: true, followLinks: false).toList(),
      false => <FileSystemEntity>[],
    };

    final revaliFiles = revaliEntities.whereType<File>();

    final paths = {
      for (final file in revaliFiles) file.path,
    };

    final serverFile = await root.getRevaliFile(result.basename);

    if (!await serverFile.exists()) {
      await serverFile.create(recursive: true);
    }

    paths.remove(serverFile.path);
    await serverFile.writeAsString(result.getContent());

    for (final MapEntry(key: basename, value: content)
        in result.getPartContent()) {
      // ensure that the path is within the revali directory
      final partFile = revali.sanitizedChildFile(basename);

      if (!await partFile.exists()) {
        await partFile.create(recursive: true);
      }

      paths.remove(partFile.path);

      await partFile.writeAsString(content);
    }

    for (final stale in paths) {
      final file = fs.file(stale);

      if (!await file.exists()) continue;

      await file.delete();
    }
  }

  Future<RevaliYaml> revaliConfig() async {
    final root = await this.root;

    final constructYamlFile = root.childFile('revali.yaml');

    RevaliYaml? revaliConfig;
    if (await constructYamlFile.exists()) {
      final yamlContent = await constructYamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as YamlMap?;

      try {
        if (yaml != null) {
          revaliConfig =
              RevaliYaml.fromJson(Map<String, dynamic>.from(yaml.value));
        }
      } catch (_) {
        logger.err('Failed to parse revali.yaml, using default configuration.');
      }
    }

    return revaliConfig ?? const RevaliYaml.none();
  }
}
