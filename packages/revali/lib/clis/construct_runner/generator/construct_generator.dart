import 'dart:convert';

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
      return await _generate(progress);
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
    final serverMakers = <ConstructMaker>[];
    final otherMakers = <ConstructMaker>[];

    for (final maker in makers) {
      final revaliConfig = await this.revaliConfig;
      final config = revaliConfig.configFor(maker);

      if (config.disabled) {
        logger.detail('Skipping ${config.name} | Disabled');
        continue;
      }

      if (maker.optIn && config.enabled == null) {
        logger.detail(
          'Skipping ${config.name} | Opt-in construct not enabled',
        );
        continue;
      }

      if (maker.isServer) {
        serverMakers.add(maker);
      } else if (maker.isBuild) {
        buildMakers.add(maker);
      } else {
        otherMakers.add(maker);
      }
    }

    if (serverMakers.length > 1) {
      logger.err('''
Only one Server Construct is allowed per project.
Found:
  - ${serverMakers.map((e) => e.name).join('\n  - ')}

To fix this issue, disable all but one Server Construct within your `revali.yaml` file.

```yaml
constructs:
  - name: server_construct
    package: construct_package
    enabled: false

''');
      throw Exception('Only one Server Construct is allowed per project');
    }

    if (generateConstructType.isBuild) {
      progress?.call('Running pre-build hooks');

      for (final maker in buildMakers) {
        final construct = await constructFromMaker<BuildConstruct>(maker);
        if (construct == null) continue;

        await construct.preBuild(buildContext, server);
      }
    }

    if (generateConstructType.isBuild) {
      progress?.call('Generating build constructs');

      for (final maker in buildMakers) {
        try {
          if (await _generateConstruct(maker, server) case final success
              when !success) {
            return null;
          }
        } catch (e) {
          logger
            ..detail('Error: $e')
            ..err(
              'Something went wrong when generating '
              'Build Construct ${maker.name}',
            );
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    } else {
      progress?.call('Generating constructs');

      for (final maker in [...serverMakers, ...otherMakers]) {
        try {
          if (await _generateConstruct(maker, server) case final success
              when !success) {
            logger.err(
              'Something went wrong when generating Construct ${maker.name}',
            );

            if (maker.isServer) {
              logger.delayed('Please check that your code is valid...');
              return null;
            }
          }
        } catch (e) {
          logger
            ..detail('Error: $e')
            ..err(
              'Something went wrong when generating '
              'Construct ${maker.name}',
            );
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (generateConstructType.isBuild) {
      progress?.call('Running post-build hooks');

      for (final maker in buildMakers) {
        final construct = await constructFromMaker<BuildConstruct>(maker);
        if (construct == null) continue;

        await construct.postBuild(buildContext, server);
      }
    }

    if (serverMakers.isEmpty) {
      logger.err('''
There are no Server Constructs in the project.

Check out the documentation for more information on how to add a Server Construct:
http://revali.dev/constructs#server-constructs
      ''');
      return null;
    }

    return server;
  }

  Future<T?> constructFromMaker<T extends Construct>(
    ConstructMaker maker,
  ) async {
    final revaliConfig = await this.revaliConfig;
    final config = revaliConfig.configFor(maker);

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
        hasNameConflict: false,
        package: null,
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
        hasNameConflict: maker.hasNameConflict,
        package: maker.package,
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
    RevaliDirectory revaliDirectory, {
    required bool hasNameConflict,
    required String? package,
  }) async {
    final revali = await (await root).getRevali();

    final fsDirectory = switch (hasNameConflict) {
      true => revali.childDirectory(
          package ??
              (throw Exception(
                'Package must be provided when there is a name conflict',
              )),
        ),
      _ => revali,
    }
        .sanitizedChildDirectory(name);

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
      final directory = construct.generate(context, server);

      await _generateDirectory(
        'server',
        directory,
        hasNameConflict: false,
        package: null,
      );

      return true;
    } catch (e) {
      logger
        ..err('Failed to generate Server Construct')
        ..err('Error: $e')
        ..delayed('Error: $e');

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
          final json =
              jsonDecode(jsonEncode(yaml.value)) as Map<String, dynamic>;
          revaliConfig = RevaliYaml.fromJson(json);
        }
      } catch (_) {
        logger.err('Failed to parse revali.yaml, using default configuration.');
      }
    }

    return __revaliConfig = revaliConfig ?? const RevaliYaml.none();
  }
}
