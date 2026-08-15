import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/error/error.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
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
  }) : mode = Mode.release,
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
  }) : mode = Mode.profile,
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
  }) : mode = Mode.debug,
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
  Directory? _stagingRoot;
  Future<void> _generateTail = Future<void>.value();

  List<CompiledExecutable> _compiledExecutables = const [];

  static const _stagingPrefix = '.revali.staging';

  Future<Directory> get root async {
    if (__root case final root?) {
      return root;
    }

    final root = await rootOf(_rootPath);

    return __root = root;
  }

  RevaliContext get context => RevaliContext(flavor: flavor, mode: mode);

  RevaliBuildContext get buildContext => RevaliBuildContext(
    flavor: flavor,
    mode: mode,
    defines: dartDefines?.defined ?? const {},
    compiledExecutables: _compiledExecutables,
  );

  Future<void> clean({
    GenerateConstructType type = GenerateConstructType.constructs,
  }) async {
    final root = await this.root;

    final server = await root.getServer();
    if (server.existsSync() && type.isConstructs) {
      await server.delete(recursive: true);
    }

    final build = await root.getBuild();
    if (build.existsSync()) {
      await build.delete(recursive: true);
    }

    if (type.isConstructs) {
      await for (final construct in root.getConstructs()) {
        if (construct.existsSync()) {
          await construct.delete(recursive: true);
        }
      }
    }
  }

  Future<List<(String, List<AnalysisError>)>> getErrors() async {
    return await routesHandler.errors();
  }

  Future<MetaServer> generate([Log progress]) async {
    final task = _generateTail.then((_) => _generate(progress));
    _generateTail = task.then((_) {}, onError: (_) {});

    try {
      return await task;
    } catch (e) {
      logger
        ..delayed(red.wrap('Error occurred while generating constructs'))
        ..delayed(red.wrap('Error: $e'));
      rethrow;
    }
  }

  Future<MetaServer> _generate(Log progress) async {
    await _prepareStaging();

    try {
      return await _generateIntoStaging(progress);
    } catch (e) {
      await _discardStaging();
      rethrow;
    }
  }

  Future<MetaServer> _generateIntoStaging(Log progress) async {
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
        logger.detail('Skipping ${config.name} | Opt-in construct not enabled');
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
      final revaliConfig = await this.revaliConfig;

      if (revaliConfig.build case final buildSettings?) {
        progress?.call('Compiling server');
        _compiledExecutables = await _compileServer(buildSettings);
      }
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
            throw Exception(
              'Something went wrong when generating '
              'Build Construct ${maker.name}',
            );
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
              throw Exception(
                'Something went wrong when generating '
                'Construct ${maker.name}',
              );
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
https://revali.dev/constructs#server-generation
      ''');
      throw Exception('There are no Server Constructs in the project.');
    }

    await _promoteStaging();

    return server;
  }

  /// Regenerates the server construct for real (mirroring what
  /// `revali_docker`'s in-container `RUN dart run revali build --type
  /// constructs --recompile` line does today, just run here on the host),
  /// then compiles it via `dart compile exe --target-os --target-arch` for
  /// every architecture [buildSettings] requests. Writes into a fixed
  /// scratch directory under `.dart_tool/` — never into `.revali/build/`
  /// directly, since `_promoteStaging` unconditionally wipes and replaces
  /// that directory after build-type constructs run.
  Future<List<CompiledExecutable>> _compileServer(
    BuildSettingsConfig buildSettings,
  ) async {
    final rootDir = await root;
    final targetOs = buildSettings.resolvedTargetOs;

    if (!TargetOs.current().canCompile(targetOs)) {
      throw Exception(
        'Cannot compile for target_os: ${targetOs.name} from a '
        '${TargetOs.current().name} host. macOS and Windows targets must be '
        'compiled on that same OS; only linux can be cross-compiled from '
        'any host.',
      );
    }

    final flavorArgs = [
      if (flavor case final f?) ...['--flavor', f],
    ];

    final constructsResult = await io.Process.run(
      'dart',
      [
        'run',
        'revali',
        'build',
        ...flavorArgs,
        '--${mode.flag}',
        '--type',
        'constructs',
        '--recompile',
      ],
      workingDirectory: rootDir.path,
      runInShell: true,
    );

    if (constructsResult.exitCode != 0) {
      logger
        ..detail('stdout: ${constructsResult.stdout}')
        ..detail('stderr: ${constructsResult.stderr}')
        ..err('Failed to regenerate server construct before compiling');

      throw Exception('Failed to regenerate server construct before compiling');
    }

    final scratchDir = fs.directory(
      p.join(rootDir.path, '.dart_tool', 'revali', 'build_artifacts'),
    );
    if (scratchDir.existsSync()) {
      await scratchDir.delete(recursive: true);
    }
    await scratchDir.create(recursive: true);

    final serverEntry = p.join(
      rootDir.path,
      '.revali',
      'server',
      'server.dart',
    );
    final defines = dartDefines?.defined ?? const {};
    final defineArgs = [
      for (final entry in defines.entries) '-D${entry.key}=${entry.value}',
    ];

    final compiled = <CompiledExecutable>[];

    for (final arch in buildSettings.resolvedTargetArch) {
      final basePath = p.join(
        scratchDir.path,
        'server-${targetOs.name}-${arch.name}',
      );
      final debugPath = buildSettings.stripDebugInfo ? '$basePath.debug' : null;

      final compileResult = await io.Process.run(
        'dart',
        [
          'compile',
          'exe',
          serverEntry,
          '-o',
          basePath,
          '--target-os',
          targetOs.name,
          '--target-arch',
          arch.name,
          if (debugPath != null) ...['-S', debugPath],
          ...defineArgs,
        ],
        workingDirectory: rootDir.path,
        runInShell: true,
      );

      if (compileResult.exitCode != 0) {
        logger
          ..detail('stdout: ${compileResult.stdout}')
          ..detail('stderr: ${compileResult.stderr}')
          ..err('Failed to compile server for ${targetOs.name}/${arch.name}');

        throw Exception(
          'Failed to compile server for ${targetOs.name}/${arch.name}',
        );
      }

      compiled.add(
        CompiledExecutable(
          targetOs: targetOs,
          targetArch: arch,
          path: basePath,
          debugInfoPath: debugPath,
        ),
      );
    }

    return compiled;
  }

  Future<void> _prepareStaging() async {
    final rootDir = await root;
    final staging = rootDir.childDirectory(
      '$_stagingPrefix.${DateTime.now().microsecondsSinceEpoch}',
    );

    await staging.create(recursive: true);
    _stagingRoot = staging;
  }

  Future<void> _promoteStaging() async {
    final staging = _stagingRoot;
    if (staging == null || !staging.existsSync()) {
      return;
    }

    final rootDir = await root;
    final revali = await rootDir.getRevali();
    final type = generateConstructType;

    if (type.isBuild && type.isConstructs) {
      await _replaceDirectory(revali, staging);
    } else if (type.isConstructs) {
      // Never delete live outputs before the new tree is in place — a wipe
      // gap leaves `server/server.dart` missing and kills headless/AI reloads
      // that restart the child mid-promote.
      if (!revali.existsSync()) {
        await revali.create(recursive: true);
      }

      await _swapConstructOutputs(revali, staging);
    } else if (type.isBuild) {
      if (!revali.existsSync()) {
        await revali.create(recursive: true);
      }

      final build = await revali.getBuild();
      if (build.existsSync()) {
        await build.delete(recursive: true);
      }

      final stagingBuild = staging.childDirectory('build');
      if (stagingBuild.existsSync()) {
        await stagingBuild.rename(build.path);
      }

      await _removeDirectory(staging);
    }

    _stagingRoot = null;
    await _cleanupOldStagingDirectories(rootDir);
  }

  /// Atomically replaces construct output dirs (e.g. `server/`) from [staging]
  /// into [revali], preserving `build/`. Each directory is swapped via rename
  /// so the live path is never absent for longer than a rename.
  Future<void> _swapConstructOutputs(
    Directory revali,
    Directory staging,
  ) async {
    final promoted = <String>{};

    for (final entity in staging.listSync()) {
      promoted.add(entity.basename);

      switch (entity) {
        case Directory():
          await _atomicReplaceDirectory(
            revali.childDirectory(entity.basename),
            entity,
          );
        case File():
          final dest = revali.childFile(entity.basename);
          if (dest.existsSync()) {
            await dest.delete();
          }
          await entity.rename(dest.path);
        default:
          throw StateError('Unexpected entity type: ${entity.runtimeType}');
      }
    }

    // Drop stale construct dirs that were not in this generation.
    if (revali.existsSync()) {
      for (final entity in revali.listSync()) {
        if (entity is! Directory) continue;
        if (entity.basename == 'build') continue;
        if (promoted.contains(entity.basename)) continue;
        await _removeDirectory(entity);
      }
    }

    await _removeDirectory(staging);
  }

  Future<void> _atomicReplaceDirectory(
    Directory target,
    Directory source,
  ) async {
    if (!source.existsSync()) {
      return;
    }

    if (!target.existsSync()) {
      await source.rename(target.path);
      return;
    }

    final backup = target.parent.childDirectory(
      '${target.basename}.bak.${DateTime.now().microsecondsSinceEpoch}',
    );

    await target.rename(backup.path);
    try {
      await source.rename(target.path);
    } catch (_) {
      if (backup.existsSync() && !target.existsSync()) {
        await backup.rename(target.path);
      }
      rethrow;
    }

    await _removeDirectory(backup);
  }

  Future<void> _discardStaging() async {
    final staging = _stagingRoot;
    if (staging != null) {
      await _removeDirectory(staging);
    }

    _stagingRoot = null;
    await _cleanupOldStagingDirectories(await root);
  }

  Future<void> _cleanupOldStagingDirectories(Directory rootDir) async {
    final activeStaging = _stagingRoot?.path;

    for (final entity in rootDir.listSync()) {
      if (entity is! Directory) continue;
      if (!entity.basename.startsWith(_stagingPrefix)) continue;
      if (entity.path == activeStaging) continue;

      await _removeDirectory(entity);
    }
  }

  Future<void> _removeDirectory(Directory directory) async {
    if (!directory.existsSync()) {
      return;
    }

    final trash = directory.parent.childDirectory(
      '${directory.basename}.${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await directory.rename(trash.path);
    } on FileSystemException {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        await _removeDirectoryContents(directory);
        if (directory.existsSync()) {
          await directory.delete();
        }
      }
      return;
    }

    try {
      await trash.delete(recursive: true);
    } on FileSystemException {
      await _removeDirectoryContents(trash);
      if (trash.existsSync()) {
        await trash.delete();
      }
    }
  }

  Future<void> _removeDirectoryContents(Directory directory) async {
    if (!directory.existsSync()) {
      return;
    }

    for (final entity in directory.listSync()) {
      if (entity is Directory) {
        await _removeDirectory(entity);
      } else {
        await entity.delete();
      }
    }
  }

  Future<void> _replaceDirectory(Directory target, Directory source) async {
    if (target.existsSync()) {
      await target.delete(recursive: true);
    }

    await source.rename(target.path);
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
        RevaliDirectory(files: constructResult.files),
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
        RevaliDirectory(files: constructResult.files),
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
    final revali =
        _stagingRoot ??
        (throw StateError(
          'Staging directory must be prepared before generating',
        ));

    final fsDirectory = switch (hasNameConflict) {
      true => revali.childDirectory(
        package ??
            (throw Exception(
              'Package must be provided when there is a name conflict',
            )),
      ),
      _ => revali,
    }.sanitizedChildDirectory(name);

    if (!fsDirectory.existsSync()) {
      await fsDirectory.create(recursive: true);
    }

    final revaliEntities = switch (fsDirectory.existsSync()) {
      true =>
        await fsDirectory.list(recursive: true, followLinks: false).toList(),
      false => <FileSystemEntity>[],
    };

    final revaliFiles = revaliEntities.whereType<File>();

    final paths = {for (final file in revaliFiles) file.path};

    for (final file in revaliDirectory.files) {
      final fileEntity = fsDirectory.sanitizedChildFile(file.fileName);

      if (!fileEntity.existsSync()) {
        await fileEntity.create(recursive: true);
      }

      paths.remove(fileEntity.path);

      if (file.bytes case final bytes?) {
        await fileEntity.writeAsBytes(bytes);
      } else {
        await fileEntity.writeAsString(file.content);
      }
    }

    for (final stale in paths) {
      final file = fs.file(stale);

      if (!file.existsSync()) continue;

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
    } catch (e, st) {
      logger
        ..err('Failed to generate Server Construct')
        ..err('Error: $e')
        ..detail('$st')
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
    if (constructYamlFile.existsSync()) {
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
