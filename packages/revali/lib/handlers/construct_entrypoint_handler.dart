import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/constructs_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:stack_trace/stack_trace.dart';

class ConstructEntrypointHandler with DirectoriesMixin {
  ConstructEntrypointHandler({
    required this.initialDirectory,
    required this.fs,
    required this.logger,
    ConstructsHandler? constructHandler,
  }) : constructHandler = constructHandler ??
            ConstructsHandler(
              fs: fs,
              logger: logger,
            );

  final String initialDirectory;
  final ConstructsHandler constructHandler;
  @override
  final FileSystem fs;
  final Logger logger;

  static const String entrypointFile = 'revali.dart';
  static const String kernelExtension = '.dill';
  static const String kernelFile = '$entrypointFile$kernelExtension';
  static const String assetsFile = 'revali.assets.json';

  Future<void> generate({bool recompile = false}) async {
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

    final needsNewKernel = await checkAssets(constructs, root);

    if (!recompile && !needsNewKernel) {
      final kernel = await root.getInternalRevaliFile(kernelFile);

      if (await kernel.exists()) {
        logger
          ..detail('Skipping entrypoint generation, using existing kernel')
          ..success('Constructs entrypoint is up to date');
        return;
      }
    }

    if (recompile) {
      logger.detail('Forcing entrypoint recompile');
    }

    final entrypointProgress =
        logger.progress('Generating constructs entrypoint');

    await createEntrypoint(
      root,
      constructs: constructs,
    );
    entrypointProgress.complete('Generated constructs entrypoint');

    final compileProgress = logger.progress('Compiling constructs entrypoint');
    await compile(root: root);
    compileProgress.complete('Compiled constructs entrypoint');
  }

  Future<bool> checkAssets(
    List<ConstructYaml> constructs,
    Directory root,
  ) async {
    final assetsFile =
        await root.getInternalRevaliFile(ConstructEntrypointHandler.assetsFile);

    Future<void> saveAssets() async {
      logger.detail('Saving assets file');
      final json = constructs.map((e) => e.toJson()).toList();

      if (!await assetsFile.exists()) {
        await assetsFile.create(recursive: true);
      }

      await assetsFile.writeAsString(jsonEncode(json));
    }

    if (!await assetsFile.exists()) {
      await saveAssets();
      return true;
    }

    List<ConstructYaml> existingConstructs;
    try {
      final existingAssets =
          jsonDecode(await assetsFile.readAsString()) as List;

      existingConstructs =
          existingAssets.map((e) => ConstructYaml.fromJson(e as Map)).toList();
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

  Future<void> createEntrypoint(
    Directory root, {
    required List<ConstructYaml> constructs,
  }) async {
    final revaliDir = await root.getInternalRevali();
    await revaliDir.create(recursive: true);

    final entrypointFile =
        revaliDir.childFile(ConstructEntrypointHandler.entrypointFile);

    if (await entrypointFile.exists()) {
      await entrypointFile.delete();
    }

    await entrypointFile.create();

    final content = entrypointContent(
      constructs,
      root: root,
    );
    await entrypointFile.writeAsString(content);
  }

  Future<File> compile({
    required Directory root,
  }) async {
    final kernel = await root.getInternalRevaliFile(kernelFile);

    final toCompile = await root.getInternalRevaliFile(entrypointFile);

    final dartTool = await root.getDartTool();
    final packageJson = dartTool.childFile('package_config.json');

    if (!await packageJson.exists()) {
      final progress = logger.progress('Running pub get');
      final result = await Process.run(
        'dart',
        [
          'pub',
          'get',
          '--no-precompile',
        ],
        workingDirectory: root.path,
      );
      progress.complete('Got dependencies');

      if (result.exitCode != 0) {
        throw Exception('Failed to get dependencies');
      }
    }

    final result = await Process.run(
      'dart',
      [
        'compile',
        'kernel',
        toCompile.path,
        '-o',
        kernel.path,
      ],
      runInShell: true,
    );

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

    if (!await file.exists()) {
      throw StateError('Script file does not exist');
    }

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
      errorListener = errorPort.listen((e) {
        e = e as List<Object?>;
        final error = e[0] ?? TypeError();
        final trace = Trace.parse(e[1] as String? ?? '').terse;

        logger
          ..err('Error in script:\n$error')
          ..detail(trace.toString());
        if (scriptExitCode == 0) scriptExitCode = 1;
      });
      try {
        await Isolate.spawnUri(
          Uri.file(file.path),
          switch (args) {
            List() => args,
            _ => args.toList(),
          },
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
            '$isolateExitCode');
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
          refer('$ConstructMaker', revaliConstruct).newInstance(
            [],
            {
              'package': literalString(yaml.packageName),
              'isServer': refer('${construct.isServer}'),
              'isBuild': refer('${construct.isBuild}'),
              'optIn': refer('${construct.optIn}'),
              'name': literalString(construct.name),
              'hasNameConflict':
                  literalBool((conflicts[construct.name] ?? []).length > 1),
              'maker': refer(
                construct.method,
                '${yaml.packageUri}${construct.path}',
              ),
            },
          ),
    ];

    final constructs0 = declareConst('_constructs')
        .assign(
          literalList(
            constructItems,
            refer('$ConstructMaker', revaliConstruct),
          ),
        )
        .statement;

    final path =
        declareConst('_root').assign(literalString(root.path)).statement;

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
          declareFinal('result')
              .assign(
                refer('runConstruct', revali).call([
                  refer('args'),
                ], {
                  'constructs': refer('_constructs'),
                  'path': refer('_root'),
                }).awaited,
              )
              .statement,
          const Code('\n'),
          refer('sendPort')
              .nullSafeProperty('send')
              .call([refer('result')]).statement,
          const Code('\n'),
          refer('exitCode', 'dart:io').assign(refer('result')).statement,
        ]),
    );

    final library = Library(
      (b) => b.body.addAll(
        [
          constructs0,
          path,
          main,
        ],
      ),
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
      logger.err('Generated build script could not be parsed.\n'
          'This is likely caused by a misconfigured builder definition.');
      // TODO(mrgnhnt): throw custom exception
      throw Exception('Failed to generate build script');
    }
  }
}
