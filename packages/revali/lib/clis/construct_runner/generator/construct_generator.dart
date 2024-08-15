import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/models/files/server_directory.dart';
import 'package:revali_construct/models/revali_build_context.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:yaml/yaml.dart';

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
    this.generateBuild = false,
  }) : _rootPath = rootPath;
  ConstructGenerator.release({
    required this.flavor,
    required this.routesHandler,
    required this.makers,
    required this.logger,
    required this.fs,
    required String rootPath,
    this.dartDefines,
    this.generateBuild = false,
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
    this.generateBuild = false,
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
    this.generateBuild = false,
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
  final bool generateBuild;

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

  Future<void> clean() async {
    final root = await this.root;

    final revali = await root.getRevali();
    if (await revali.exists()) {
      await revali.delete(recursive: true);
    }
  }

  MetaServer? __server;
  Future<MetaServer> get server async {
    if (__server case final server?) {
      return server;
    }

    return __server = await routesHandler.parse();
  }

  Future<bool> generate() async {
    try {
      await _generate();

      return true;
    } catch (e) {
      logger
        ..delayed(red.wrap('Error occurred while generating constructs'))
        ..delayed(red.wrap('$e'));
    }

    return false;
  }

  Future<void> _generate() async {
    final buildMakers = <ConstructMaker>[];

    if (generateBuild) {
      for (final construct in makers) {
        if (!construct.isBuild) continue;

        buildMakers.add(construct);
      }
    }

    for (final maker in buildMakers) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) continue;

      await construct.preBuild(buildContext, await server);
    }

    for (final maker in makers) {
      if (maker.isBuild && !generateBuild) {
        logger.detail(
          'Skipping build construct ${maker.name} '
          'because build is disabled',
        );

        continue;
      }
      await _generateConstruct(maker);
    }

    for (final maker in buildMakers) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) continue;

      await construct.postBuild(buildContext, await server);
    }
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

  Future<void> _generateConstruct(ConstructMaker maker) async {
    if (maker.isServer) {
      final construct = await constructFromMaker<ServerConstruct>(maker);
      if (construct == null) {
        throw Exception('Server construct cannot be null');
      }

      await _generateServerConstruct(construct);
    } else if (maker.isBuild) {
      final construct = await constructFromMaker<BuildConstruct>(maker);
      if (construct == null) return;

      await _generateBuildConstruct(construct);
    } else {
      final construct = await constructFromMaker<Construct>(maker);
      if (construct == null) return;

      await _generateOtherConstruct(construct, maker);
    }
  }

  Future<void> _generateBuildConstruct(BuildConstruct construct) async {
    final constructResult = construct.generate(buildContext, await server);

    await _generateDirectory(
      RevaliDirectory(
        name: 'build',
        files: constructResult.files,
      ),
    );
  }

  Future<void> _generateOtherConstruct(
    Construct construct,
    ConstructMaker maker,
  ) async {
    final constructResult = construct.generate(context, await server);

    await _generateDirectory(
      RevaliDirectory(
        name: maker.name,
        files: constructResult.files,
      ),
    );
  }

  Future<void> _generateDirectory(
    RevaliDirectory revaliDirectory,
  ) async {
    final revali = await (await root).getRevali();

    final fsDirectory = revali.sanitizedChildDirectory(revaliDirectory.name);

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

  Future<void> _generateServerConstruct(ServerConstruct construct) async {
    final ServerDirectory(files: [result]) =
        construct.generate(context, await server);

    await _generateDirectory(
      RevaliDirectory(
        name: 'server',
        files: [result, ...result.parts],
      ),
    );
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
