import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:package_config/package_config.dart';
import 'package:revali/handlers/constructs_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/kernel_cache.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:stack_trace/stack_trace.dart';

class ConstructEntrypointHandler with DirectoriesMixin {
  ConstructEntrypointHandler({
    required this.initialDirectory,
    required this.fs,
    required this.logger,
    ConstructsHandler? constructHandler,
  }) : constructHandler =
           constructHandler ?? ConstructsHandler(fs: fs, logger: logger);

  final String initialDirectory;
  final ConstructsHandler constructHandler;
  @override
  final FileSystem fs;
  final Logger logger;

  static const String entrypointFile = 'revali.dart';
  static const String kernelExtension = '.dill';
  static const String kernelFile = '$entrypointFile$kernelExtension';
  static const String assetsFile = 'revali.assets.json';
  static const String rootArgName = '--root';

  /// Generates / refreshes the construct kernel.
  ///
  /// Returns `true` when the construct isolate should run (server/client gen).
  /// Returns `false` when [skipIfFresh] short-circuits a fully up-to-date
  /// package.
  Future<bool> generate({
    bool recompile = false,
    bool skipIfFresh = false,
  }) async {
    final root = await rootOf(initialDirectory);
    logger.detail('Root: ${root.path}');

    final constructProgress = logger.progress('Retrieving constructs');
    final constructs = await constructHandler.constructDepsFrom(root);
    constructProgress.complete('Retrieved constructs');

    logger.detail('Constructs Dependencies: ${constructs.length}');
    for (final dep in constructs) {
      logger.detail('Package: ${dep.packageName}');
      for (final construct in dep.constructs) {
        logger.detail(' - ${construct.name}');
      }
    }

    final fingerprint = constructSetFingerprint(constructs);
    final cacheDir = resolveKernelCacheDir(
      fs,
      root,
    ).childDirectory(fingerprint);
    final cachedKernel = cacheDir.childFile(kernelFile);
    final cachedEntrypoint = cacheDir.childFile(entrypointFile);

    if (skipIfFresh && !recompile) {
      final outputsFresh = await _packageOutputsAreFresh(root);
      // Use local kernel only — a sibling publishing to the shared cache must
      // not cause this package to skip regenerating its `.revali` outputs.
      final localKernelForSkip = await root.getInternalRevaliFile(kernelFile);
      final kernelFresh =
          localKernelForSkip.existsSync() &&
          !await kernelIsStale(constructs, root);
      if (outputsFresh && kernelFresh) {
        logger.success('Generated outputs are fresh — skipping generate');
        return false;
      }
    }

    final assetsChanged = await checkAssets(constructs, root);
    final localKernel = await root.getInternalRevaliFile(kernelFile);
    final localEntrypoint = await root.getInternalRevaliFile(entrypointFile);

    // Staleness is always against the *local* kernel. A fresh shared cache must
    // be installed locally — never treated as "already up to date" in-place.
    final localKernelStale = await kernelIsStale(constructs, root);
    final cacheIsFresh =
        cachedKernel.existsSync() &&
        !await _fileNewerThanSources(cachedKernel, constructs, root);

    if (!recompile && !assetsChanged) {
      if (!localKernelStale && localKernel.existsSync()) {
        logger
          ..detail('Skipping entrypoint generation, using existing kernel')
          ..success('Constructs entrypoint is up to date');
        return true;
      }

      if (cacheIsFresh) {
        await _installCachedKernel(
          root: root,
          cachedKernel: cachedKernel,
          cachedEntrypoint: cachedEntrypoint,
          localKernel: localKernel,
          localEntrypoint: localEntrypoint,
        );
        logger.success('Constructs entrypoint restored from shared cache');
        return true;
      }
    }

    if (recompile) {
      logger.detail('Forcing entrypoint recompile');
    }

    final entrypointProgress = logger.progress(
      'Generating constructs entrypoint',
    );

    await createEntrypoint(root, constructs: constructs);
    entrypointProgress.complete('Generated constructs entrypoint');

    // Serialize compile/publish so parallel packages share one ~4s compile.
    await _withSharedCacheLock(cacheDir, () async {
      // Re-check after lock — another package may have compiled.
      if (!recompile &&
          cachedKernel.existsSync() &&
          !await _fileNewerThanSources(cachedKernel, constructs, root)) {
        await _installCachedKernel(
          root: root,
          cachedKernel: cachedKernel,
          cachedEntrypoint: cachedEntrypoint,
          localKernel: localKernel,
          localEntrypoint: localEntrypoint,
        );
        logger.success('Constructs entrypoint reused from shared cache');
        return;
      }

      final compileProgress = logger.progress(
        'Compiling constructs entrypoint',
      );
      await compile(root: root);
      compileProgress.complete('Compiled constructs entrypoint');

      await _publishKernelToCache(
        cacheDir: cacheDir,
        localKernel: localKernel,
        localEntrypoint: localEntrypoint,
      );
    });
    return true;
  }

  /// Exclusive lock around shared-cache compile so concurrent packages
  /// compile the construct-set kernel once.
  Future<void> _withSharedCacheLock(
    Directory cacheDir,
    Future<void> Function() action,
  ) async {
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    final lockPath = cacheDir.childFile('.compile.lock').path;
    io.RandomAccessFile? raf;
    Object? lastError;

    for (var attempt = 0; attempt < 240; attempt++) {
      try {
        raf = await io.File(lockPath).open(mode: io.FileMode.write);
        await raf.lock();
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        await raf?.close();
        raf = null;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    if (raf == null) {
      logger.detail('Could not acquire kernel cache lock: $lastError');
      // Proceed unlocked rather than fail the suite.
      await action();
      return;
    }

    try {
      await action();
    } finally {
      try {
        await raf.unlock();
      } catch (_) {}
      await raf.close();
    }
  }

  Future<bool> _packageOutputsAreFresh(Directory root) async {
    final server = root
        .childDirectory('.revali')
        .childDirectory('server')
        .childFile('server.dart');
    final outputs = <File>[server];

    final clientDir = root
        .childDirectory('.revali')
        .childDirectory('revali_client');
    if (clientDir.existsSync()) {
      final clientServer = clientDir
          .childDirectory('lib')
          .childDirectory('src')
          .childFile('server.dart');
      if (clientServer.existsSync()) {
        outputs.add(clientServer);
      }
    }

    final kernel = await root.getInternalRevaliFile(kernelFile);

    return outputsAreFresh(
      fs: fs,
      outputs: outputs,
      inputDirs: [root.childDirectory('routes'), root.childDirectory('lib')],
      extraFiles: [if (kernel.existsSync()) kernel],
    );
  }

  Future<void> _installCachedKernel({
    required Directory root,
    required File cachedKernel,
    required File cachedEntrypoint,
    required File localKernel,
    required File localEntrypoint,
  }) async {
    final revaliDir = await root.getInternalRevali();
    if (!revaliDir.existsSync()) {
      await revaliDir.create(recursive: true);
    }

    if (cachedEntrypoint.existsSync()) {
      await cachedEntrypoint.copy(localEntrypoint.path);
    }
    await cachedKernel.copy(localKernel.path);
  }

  Future<void> _publishKernelToCache({
    required Directory cacheDir,
    required File localKernel,
    required File localEntrypoint,
  }) async {
    try {
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      if (localEntrypoint.existsSync()) {
        await localEntrypoint.copy(cacheDir.childFile(entrypointFile).path);
      }
      if (localKernel.existsSync()) {
        await localKernel.copy(cacheDir.childFile(kernelFile).path);
      }
      logger.detail('Published kernel to shared cache: ${cacheDir.path}');
    } catch (e) {
      logger.detail('Could not publish kernel to shared cache: $e');
    }
  }

  Future<bool> checkAssets(
    List<ConstructYaml> constructs,
    Directory root,
  ) async {
    final assetsFile = await root.getInternalRevaliFile(
      ConstructEntrypointHandler.assetsFile,
    );

    Future<void> saveAssets() async {
      logger.detail('Saving assets file');
      final json = constructs.map((e) => e.toJson()).toList();

      if (!assetsFile.existsSync()) {
        await assetsFile.create(recursive: true);
      }

      await assetsFile.writeAsString(jsonEncode(json));
    }

    if (!assetsFile.existsSync()) {
      await saveAssets();
      return true;
    }

    List<ConstructYaml> existingConstructs;
    try {
      final existingAssets =
          jsonDecode(await assetsFile.readAsString()) as List;

      existingConstructs = existingAssets
          .map((e) => ConstructYaml.fromJson(e as Map))
          .toList();
    } catch (e) {
      await saveAssets();
      return true;
    }

    const deepEquality = DeepCollectionEquality();

    if (deepEquality.equals(constructs, existingConstructs)) {
      logger.detail('Assets are up to date');
      return false;
    }

    await saveAssets();
    return true;
  }

  /// Returns true when construct package sources are newer than the compiled
  /// kernel. Path dependencies (common in monorepos) change without updating
  /// construct.yaml, so asset equality alone is not enough.
  ///
  /// Also checks path packages the entrypoint imports (notably
  /// `package:revali`) — the kernel AOT-compiles those sources, so edits
  /// there must invalidate it.
  Future<bool> kernelIsStale(
    List<ConstructYaml> constructs,
    Directory root, {
    File? cachedKernel,
  }) async {
    final kernel = await root.getInternalRevaliFile(kernelFile);
    final candidates = <File>[
      if (kernel.existsSync()) kernel,
      if (cachedKernel != null && cachedKernel.existsSync()) cachedKernel,
    ];

    if (candidates.isEmpty) {
      return true;
    }

    // Use the newest available kernel as the baseline.
    candidates.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return _fileNewerThanSources(candidates.first, constructs, root);
  }

  Future<bool> _fileNewerThanSources(
    File kernel,
    List<ConstructYaml> constructs,
    Directory root,
  ) async {
    final kernelModified = kernel.lastModifiedSync();

    Future<bool> libNewerThanKernel(Directory packageRoot) async {
      final libDir = packageRoot.childDirectory('lib');
      if (!libDir.existsSync()) {
        return false;
      }

      await for (final entity in libDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        if (entity.lastModifiedSync().isAfter(kernelModified)) {
          logger.detail('Source newer than kernel: ${entity.path}');
          return true;
        }
      }
      return false;
    }

    for (final construct in constructs) {
      if (await libNewerThanKernel(fs.directory(construct.packagePath))) {
        return true;
      }
    }

    // Entrypoint imports package:revali (and transitive path deps). Without
    // this, monorepo edits to the CLI/analyzer never rebuild the construct
    // kernel and hot-reload keeps running stale code.
    try {
      final packageConfigFile = await root.getPackageConfig();
      if (packageConfigFile.existsSync()) {
        final config = await loadPackageConfigUri(
          packageConfigFile.absolute.uri,
        );
        for (final package in config.packages) {
          if (!package.root.isScheme('file')) continue;
          if (package.name != 'revali' && !package.name.startsWith('revali_')) {
            continue;
          }
          final packageRoot = fs.directory(package.root.toFilePath());
          if (await libNewerThanKernel(packageRoot)) {
            return true;
          }
        }
      }
    } catch (e) {
      logger.detail('Could not check path packages for kernel staleness: $e');
    }

    return false;
  }

  Future<void> createEntrypoint(
    Directory root, {
    required List<ConstructYaml> constructs,
  }) async {
    final revaliDir = await root.getInternalRevali();
    await revaliDir.create(recursive: true);

    final entrypointFile = revaliDir.childFile(
      ConstructEntrypointHandler.entrypointFile,
    );

    if (entrypointFile.existsSync()) {
      await entrypointFile.delete();
    }

    await entrypointFile.create();

    final content = entrypointContent(constructs, root: root);
    await entrypointFile.writeAsString(content);
  }

  Future<File> compile({required Directory root}) async {
    final kernel = await root.getInternalRevaliFile(kernelFile);

    final toCompile = await root.getInternalRevaliFile(entrypointFile);

    var packageConfig = await root.getPackageConfig();

    if (!packageConfig.existsSync()) {
      logger.detail(
        'package_config missing before pub get: ${packageConfig.path} '
        '(project root: ${root.path})',
      );

      final progress = logger.progress('Running pub get');
      final result = await io.Process.run('dart', [
        'pub',
        'get',
        '--no-precompile',
      ], workingDirectory: root.path);
      progress.complete('Got dependencies');

      if (result.exitCode != 0) {
        throw Exception(
          'Failed to get dependencies in ${root.path}\n'
          'stdout: ${result.stdout}\n'
          'stderr: ${result.stderr}',
        );
      }

      packageConfig = await root.getPackageConfig();
      if (!packageConfig.existsSync()) {
        throw Exception(
          'package_config.json still missing after pub get at '
          '${packageConfig.path} (project root: ${root.path})',
        );
      }

      logger.detail(
        'package_config resolved after pub get: ${packageConfig.path}',
      );
    }

    final result = await io.Process.run('dart', [
      'compile',
      'kernel',
      toCompile.path,
      '-o',
      kernel.path,
    ], runInShell: true);

    if (result.exitCode != 0) {
      throw Exception('''
Failed to compile entrypoint
Error:
${result.stderr}''');
    }

    return kernel;
  }

  Future<void> run(Iterable<String> args) async {
    ReceivePort? exitPort;
    ReceivePort? errorPort;
    ReceivePort? messagePort;
    StreamSubscription<dynamic>? errorListener;
    int? scriptExitCode;

    final root = await rootOf(initialDirectory);
    final file = await root.getInternalRevaliFile(kernelFile);

    if (!file.existsSync()) {
      throw StateError('Script file does not exist');
    }

    // Pass the project root so a shared kernel can target any package.
    final isolateArgs = <String>[
      ...switch (args) {
        List<String>() => args,
        _ => args.toList(),
      },
      if (!args.contains(rootArgName)) ...[rootArgName, root.path],
    ];

    var tryCount = 0;
    var succeeded = false;
    while (tryCount < 2 && !succeeded) {
      tryCount++;
      exitPort?.close();
      errorPort?.close();
      messagePort?.close();
      await errorListener?.cancel();

      exitPort = ReceivePort();
      errorPort = ReceivePort();
      messagePort = ReceivePort();
      errorListener = errorPort.listen((event) {
        final e = event as List<Object?>;
        final error = e[0] ?? TypeError();
        final trace = Trace.parse(e[1] as String? ?? '').terse;

        logger
          ..err('Something unexpected happened, please report this issue\n')
          ..info('--------')
          ..info('$error')
          ..info(trace.toString());
        if (scriptExitCode == 0) scriptExitCode = 1;
      });
      try {
        await Isolate.spawnUri(
          Uri.file(file.path),
          isolateArgs,
          messagePort.sendPort,
          onExit: exitPort.sendPort,
          onError: errorPort.sendPort,
        );
        succeeded = true;
      } on IsolateSpawnException catch (e) {
        if (tryCount > 1) {
          logger.err(
            'Failed to spawn build script after retry. '
            'This is likely due to a misconfigured construct definition.\n'
            '$e',
          );
          messagePort.sendPort.send(1);
          exitPort.sendPort.send(null);
        } else {
          logger.err(
            'Error spawning build script isolate, '
            'this is likely due to a Dart '
            'SDK update. Deleting precompiled script and retrying...',
          );
        }

        try {
          await file.delete();
        } catch (e) {
          logger.err('Failed to delete precompiled script: $e');
        }
      }
    }

    StreamSubscription<dynamic>? exitCodeListener;
    exitCodeListener = messagePort!.listen((isolateExitCode) {
      if (isolateExitCode is int) {
        scriptExitCode = isolateExitCode;
      } else {
        throw StateError(
          'Bad response from isolate, expected an exit code but got '
          '$isolateExitCode',
        );
      }
      exitCodeListener!.cancel();
      exitCodeListener = null;
    });
    await exitPort?.first;
    await errorListener?.cancel();
    await exitCodeListener?.cancel();
  }

  String entrypointContent(
    Iterable<ConstructYaml> constructs, {
    required Directory root,
  }) {
    const revaliConstruct = 'package:revali_construct/revali_construct.dart';
    const revali = 'package:revali/revali.dart';

    final conflicts = <String, List<String>>{};

    for (final yaml in constructs) {
      for (final construct in yaml.constructs) {
        (conflicts[construct.name] ??= []).add(yaml.packageName);
      }
    }

    final constructItems = [
      for (final yaml in constructs)
        for (final construct in yaml.constructs)
          refer('$ConstructMaker', revaliConstruct).newInstance([], {
            'package': literalString(yaml.packageName),
            'isServer': refer('${construct.isServer}'),
            'isBuild': refer('${construct.isBuild}'),
            'optIn': refer('${construct.optIn}'),
            'name': literalString(construct.name),
            'hasNameConflict': literalBool(
              (conflicts[construct.name] ?? []).length > 1,
            ),
            'maker': refer(
              construct.method,
              '${yaml.packageUri}${construct.path}',
            ),
          }),
    ];

    final constructs0 = declareConst('_constructs')
        .assign(
          literalList(
            constructItems,
            refer('$ConstructMaker', revaliConstruct),
          ),
        )
        .statement;

    // Fallback root only — runtime prefers `--root` so kernels are shareable.
    final path = declareConst(
      '_root',
    ).assign(literalString(root.path.replaceAll(r'\', '/'))).statement;

    final resolveRoot = Method(
      (b) => b
        ..name = '_resolveRoot'
        ..returns = refer('String')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'args'
              ..type = TypeReference(
                (t) => t
                  ..symbol = 'List'
                  ..types.add(refer('String')),
              ),
          ),
        )
        ..body = Block.of([
          const Code('for (var i = 0; i < args.length - 1; i++) {'),
          const Code("if (args[i] == '$rootArgName') return args[i + 1];"),
          const Code('}'),
          refer('_root').returned.statement,
        ]),
    );

    final main = Method(
      (b) => b
        ..name = 'main'
        ..returns = refer('void')
        ..modifier = MethodModifier.async
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'args'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'List'
                  ..types.add(refer('String')),
              ),
          ),
        )
        ..optionalParameters.add(
          Parameter(
            (b) => b
              ..name = 'sendPort'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'SendPort'
                  ..url = 'dart:isolate'
                  ..isNullable = true,
              ),
          ),
        )
        ..body = Block.of([
          declareFinal(
            'root',
          ).assign(refer('_resolveRoot').call([refer('args')])).statement,
          declareFinal('result')
              .assign(
                refer('runConstruct', revali)
                    .call(
                      [refer('args')],
                      {
                        'constructs': refer('_constructs'),
                        'path': refer('root'),
                      },
                    )
                    .awaited,
              )
              .statement,
          const Code('\n'),
          refer(
            'sendPort',
          ).nullSafeProperty('send').call([refer('result')]).statement,
          const Code('\n'),
          refer('exitCode', 'dart:io').assign(refer('result')).statement,
        ]),
    );

    final library = Library(
      (b) => b.body.addAll([constructs0, path, resolveRoot, main]),
    );

    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      useNullSafetySyntax: true,
    );
    try {
      final content = StringBuffer()
        ..writeln('// ignore_for_file: directives_ordering')
        ..writeln(library.accept(emitter));

      final clean = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(content.toString());

      return clean;
    } on FormatterException {
      logger.err(
        'Generated build script could not be parsed.\n'
        'This is likely caused by a misconfigured builder definition.',
      );
      // TODO(mrgnhnt): throw custom exception
      throw Exception('Failed to generate build script');
    }
  }
}
