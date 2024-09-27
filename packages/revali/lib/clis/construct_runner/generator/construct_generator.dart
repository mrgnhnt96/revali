import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:yaml/yaml.dart';

typedef Log = void Function(String)?;

class ConstructGenerator with DirectoriesMixin {
  ConstructGenerator({
    required this.mode,
    required this.flavor,
    required this.routesHandler,
    required this.makers,
    required this.logger,
    required this.fs,
    required String rootPath,
    this.dartDefines,
    this.generateConstructType = GenerateConstructType.constructs,
  }) : _rootPath = rootPath;
  ConstructGenerator.release({
    required this.flavor,
    required this.routesHandler,
    required this.makers,
    required this.logger,
    required this.fs,
    required String rootPath,
    this.dartDefines,
    this.generateConstructType = GenerateConstructType.constructs,
  })  : mode = Mode.release,
        _rootPath = rootPath;
  ConstructGenerator.profile({
    required this.flavor,
    required this.routesHandler,
    required this.makers,
    required this.logger,
    required this.fs,
    required String rootPath,
    this.dartDefines,
    this.generateConstructType = GenerateConstructType.constructs,
  })  : mode = Mode.profile,
        _rootPath = rootPath;
  ConstructGenerator.debug({
    required this.flavor,
    required this.routesHandler,
    required this.makers,
    required this.logger,
    required this.fs,
    required String rootPath,
    this.dartDefines,
    this.generateConstructType = GenerateConstructType.constructs,
  })  : mode = Mode.debug,
        _rootPath = rootPath;

  final Mode mode;
  final String? flavor;
  final RoutesHandler routesHandler;
  final List<ConstructMaker> makers;
  final Logger logger;
  @override
  final FileSystem fs;
  final String _rootPath;
  final DartDefine? dartDefines;
  final GenerateConstructType generateConstructType;

  Directory? __root;
  Future<Directory> get root async {
    if (__root case final root?) {
      return root;
    }

    final root = await rootOf(_rootPath);

    return __root = root;
  }

  RevaliContext get context => RevaliContext(
        flavor: flavor,
        mode: mode,
      );

  RevaliBuildContext get buildContext => RevaliBuildContext(
        flavor: flavor,
        mode: mode,
        defines: dartDefines?.defined ?? const {},
      );

  Future<void> clean({
    GenerateConstructType type = GenerateConstructType.constructs,
  }) async {
    final root = await this.root;

    final server = await root.getServer();
    if (await server.exists() && type.isConstructs) {
      await server.delete(recursive: true);
    }

    final build = await root.getBuild();
    if (await build.exists()) {
      await build.delete(recursive: true);
    }

    if (type.isConstructs) {
      await for (final construct in root.getConstructs()) {
        if (await construct.exists()) {
          await construct.delete(recursive: true);
        }
      }
    }
  }

  Future<MetaServer?> generate([Log progress]) async {
    try {
      return _generate(progress);
    } catch (e) {
      logger
        ..delayed(red.wrap('Error occurred while generating constructs'))
        ..delayed(red.wrap('Error: $e'));
    }

    return null;
  }

  Future<MetaServer?> _generate(Log progress) async {
    final server = await routesHandler.parse();

    final buildMakers = <ConstructMaker>[];

    if (generateConstructType.isBuild) {
      for (final construct in makers) {
        if (!construct.isBuild) continue;

        buildMakers.add(construct);
      }
    }

    if (generateConstructType.isBuild) {
      progress?.call('Running pre-build hooks');
    }

    for (final maker in buildMakers) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) continue;

      await construct.preBuild(buildContext, server);
    }

    if (generateConstructType.isConstructs) {
      progress?.call('Generating constructs');

      for (final maker in makers) {
        if (maker.isBuild && generateConstructType.isNotBuild) {
          logger.detail(
            'Skipping build construct ${maker.name} '
            'because build is disabled',
          );

          continue;
        }
        if (await _generateConstruct(maker, server) case final success
            when !success) {
          return null;
        }
      }
    } else {
      progress?.call('Generating build constructs');

      for (final maker in buildMakers) {
        if (await _generateConstruct(maker, server) case final success
            when !success) {
          return null;
        }
      }
    }

    if (generateConstructType.isBuild) {
      progress?.call('Running post-build hooks');
    }

    for (final maker in buildMakers) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) continue;

      await construct.postBuild(buildContext, server);
    }

    return server;
  }

  Future<T?> constructFromMaker<T extends Construct>(
    ConstructMaker maker,
  ) async {
    final revaliConfig = await this.revaliConfig;
    final config = revaliConfig.configFor(maker);

    if (config.disabled) {
      if (maker.isServer) {
        logger.warn(
          '${config.name} cannot be disabled,'
          ' because it is the $ServerConstruct',
        );
      } else {
        logger.detail('skipping ${config.name}');
        return null;
      }
    }

    final result = maker.maker(config.constructOptions);

    if (result is! T) {
      throw Exception(
        'Invalid type for construct! ${result.runtimeType} '
        'must be of type $T',
      );
    }

    return result;
  }

  Future<bool> _generateConstruct(
    ConstructMaker maker,
    MetaServer server,
  ) async {
    if (maker.isServer) {
      final construct = await constructFromMaker<ServerConstruct>(maker);
      if (construct == null) {
        throw Exception('Server construct cannot be null');
      }

      if (await _generateServerConstruct(construct, server) case final success
          when !success) {
        return false;
      }
    } else if (maker.isBuild) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) return false;

      if (await _generateBuildConstruct(construct, server) case final success
          when !success) {
        return false;
      }
    } else {
      final construct = await constructFromMaker<Construct>(maker);
      if (construct == null) return false;

      if (await _generateOtherConstruct(construct, maker, server)
          case final success when !success) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _generateBuildConstruct(
    BuildConstruct construct,
    MetaServer server,
  ) async {
    try {
      final constructResult = construct.generate(buildContext, server);

      await _generateDirectory(
        'build',
        RevaliDirectory(
          files: constructResult.files,
        ),
      );

      return true;
    } catch (e) {
      logger
        ..err('Failed to generate Build Construct')
        ..err('Error: $e');

      return false;
    }
  }

  Future<bool> _generateOtherConstruct(
    Construct construct,
    ConstructMaker maker,
    MetaServer server,
  ) async {
    try {
      final constructResult = construct.generate(context, server);

      await _generateDirectory(
        maker.name,
        RevaliDirectory(
          files: constructResult.files,
        ),
      );

      return true;
    } catch (e) {
      logger
        ..err('Failed to generate ${maker.name}')
        ..err('Error: $e');

      return false;
    }
  }

  Future<void> _generateDirectory(
    String name,
    RevaliDirectory revaliDirectory,
  ) async {
    final revali = await (await root).getRevali();

    final fsDirectory = revali.sanitizedChildDirectory(name);

    if (!await fsDirectory.exists()) {
      await fsDirectory.create(recursive: true);
    }

    final revaliEntities = switch (await fsDirectory.exists()) {
      true =>
        await fsDirectory.list(recursive: true, followLinks: false).toList(),
      false => <FileSystemEntity>[],
    };

    final revaliFiles = revaliEntities.whereType<File>();

    final paths = {
      for (final file in revaliFiles) file.path,
    };

    for (final file in revaliDirectory.files) {
      final fileEntity = fsDirectory.sanitizedChildFile(file.fileName);

      if (!await fileEntity.exists()) {
        await fileEntity.create(recursive: true);
      }

      paths.remove(fileEntity.path);

      await fileEntity.writeAsString(file.content);
    }

    for (final stale in paths) {
      final file = fs.file(stale);

      if (!await file.exists()) continue;

      await file.delete();
    }
  }

  Future<bool> _generateServerConstruct(
    ServerConstruct construct,
    MetaServer server,
  ) async {
    try {
      final ServerDirectory(files: [result]) =
          construct.generate(context, server);

      await _generateDirectory(
        'server',
        RevaliDirectory(
          files: [result, ...result.parts],
        ),
      );

      return true;
    } catch (e) {
      logger
        ..err('Failed to generate Server Construct')
        ..err('Error: $e');

      return false;
    }
  }

  RevaliYaml? __revaliConfig;
  Future<RevaliYaml> get revaliConfig async {
    if (__revaliConfig case final revaliConfig?) {
      return revaliConfig;
    }

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

    return __revaliConfig = revaliConfig ?? const RevaliYaml.none();
  }
}
