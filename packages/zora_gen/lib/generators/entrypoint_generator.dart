import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:file/file.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:zora_gen/extensions/directory_extensions.dart';
import 'package:zora_gen/mixins/directories_mixin.dart';
import 'package:zora_gen/handlers/constructs_handler.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class EntrypointGenerator with DirectoriesMixin {
  EntrypointGenerator({
    required this.initialDirectory,
    ConstructsHandler? constructHandler,
    required this.fs,
  }) : constructHandler = constructHandler ?? ConstructsHandler(fs: fs);

  final String initialDirectory;
  final ConstructsHandler constructHandler;
  final FileSystem fs;

  static const String entrypointFile = 'zora.dart';
  static const String kernelExtension = 'dill';
  static const String kernelFile = '$entrypointFile$kernelExtension';
  static const String assetsFile = 'zora.assets.json';

  Future<File> generate() async {
    final root = await rootOf(initialDirectory);
    final constructs = await constructHandler.constructDepsFrom(root);

    final needsNewKernel = await checkAssets(constructs, root);

    if (!needsNewKernel) {
      final kernel = await root.getInternalZoraFile(kernelFile);

      if (await kernel.exists()) {
        return kernel;
      }
    }

    await createEntrypoint(
      root,
      constructs: constructs,
    );

    final kernel = await compile(
      root: root,
    );

    return kernel;
  }

  Future<bool> checkAssets(
    List<ConstructYaml> constructs,
    Directory root,
  ) async {
    final assetsFile =
        await root.getInternalZoraFile(EntrypointGenerator.assetsFile);

    Future<void> saveAssets() async {
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
          existingAssets.map((e) => ConstructYaml.fromJson(e)).toList();
    } catch (e) {
      await saveAssets();
      return true;
    }

    final deepEquality = const DeepCollectionEquality();

    if (deepEquality.equals(constructs, existingConstructs)) {
      return false;
    }

    await saveAssets();
    return true;
  }

  Future<void> createEntrypoint(
    Directory root, {
    required List<ConstructYaml> constructs,
  }) async {
    final zoraDir = await root.getInternalZora();
    await zoraDir.create(recursive: true);

    final entrypointFile =
        zoraDir.childFile(EntrypointGenerator.entrypointFile);

    if (await entrypointFile.exists()) {
      await entrypointFile.delete();
    }

    await entrypointFile.create();

    final content = this.entrypointContent(
      constructs,
      root: root,
    );
    await entrypointFile.writeAsString(content);
  }

  Future<File> compile({
    required Directory root,
  }) async {
    final kernel = await root.getInternalZoraFile(kernelFile);

    if (await kernel.exists()) {
      return kernel;
    }

    final toCompile = await root.getInternalZoraFile(entrypointFile);

    final dartTool = await root.getDartTool();
    final packageJson = dartTool.childFile('package_config.json');

    if (!await packageJson.exists()) {
      final result = await Process.run(
        'dart',
        [
          'pub',
          'get',
          '--no-precompile',
        ],
        workingDirectory: root.path,
      );

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
      throw Exception('Failed to compile entrypoint');
    }

    return kernel;
  }

  Future<void> run(File file, List<String> args) async {
    ReceivePort? exitPort;
    ReceivePort? errorPort;
    ReceivePort? messagePort;
    StreamSubscription? errorListener;
    int? scriptExitCode;

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

        print('Error in script: $error');
        print(trace);
        if (scriptExitCode == 0) scriptExitCode = 1;
      });
      try {
        await Isolate.spawnUri(
          Uri.file(file.path),
          args,
          messagePort.sendPort,
          errorsAreFatal: true,
          onExit: exitPort.sendPort,
          onError: errorPort.sendPort,
        );
        succeeded = true;
      } on IsolateSpawnException catch (e) {
        if (tryCount > 1) {
          print(
            'Failed to spawn build script after retry. '
            'This is likely due to a misconfigured builder definition.\n'
            '$e',
          );
          messagePort.sendPort.send(1);
          exitPort.sendPort.send(null);
        } else {
          print(
              'Error spawning build script isolate, this is likely due to a Dart '
              'SDK update. Deleting precompiled script and retrying...');
        }

        try {
          await file.delete();
        } catch (e) {
          print('Failed to delete precompiled script: $e');
        }
      }
    }

    StreamSubscription? exitCodeListener;
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
    const zora_gen_core = 'package:zora_gen_core/zora_gen_core.dart';
    const zora_gen = 'package:zora_gen/zora_gen.dart';

    final constructItems = [
      for (final yaml in constructs)
        for (final construct in yaml.constructs)
          refer('$ConstructMaker', zora_gen_core).newInstance(
            [],
            {
              // TODO: figure out how to represent a literal string
              'package': CodeExpression(Code("'${yaml.packageName}'")),
              'isRouter': refer('${construct.isRouter}'),
              'name': CodeExpression(Code("'${construct.name}'")),
              'maker': refer(
                  construct.method, '${yaml.packageUri}${construct.path}'),
            },
          ),
    ];

    final _constructs = declareFinal('_constructs')
        .assign(
          literalList(
            constructItems,
            refer('$ConstructMaker', zora_gen_core),
          ),
        )
        .statement;

    final _path =
        declareConst('_routes').assign(literalString(root.path)).statement;

    final main = Method((b) => b
      ..name = 'main'
      ..returns = refer('void')
      ..modifier = MethodModifier.async
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'args'
        ..type = TypeReference((b) => b
          ..symbol = 'List'
          ..types.add(refer('String')))))
      ..optionalParameters.add(Parameter((b) => b
        ..name = 'sendPort'
        ..type = TypeReference((b) => b
          ..symbol = 'SendPort'
          ..url = 'dart:isolate'
          ..isNullable = true)))
      ..body = Block.of([
        declareFinal('result')
            .assign(
              refer('run', zora_gen).call([
                refer('args'),
              ], {
                'constructs': refer('_constructs'),
                'path': refer('_routes'),
              }).awaited,
            )
            .statement,
        Code('\n'),
        refer('sendPort')
            .nullSafeProperty('send')
            .call([refer('result')]).statement,
        Code('\n'),
        refer('exitCode', 'dart:io').assign(refer('result')).statement,
      ]));

    final library = Library(
      (b) => b.body.addAll(
        [
          _constructs,
          _path,
          main,
        ],
      ),
    );

    final emitter = DartEmitter(
        allocator: Allocator.simplePrefixing(), useNullSafetySyntax: true);
    try {
      final content = StringBuffer()
        ..writeln('// ignore_for_file: directives_ordering')
        ..writeln(library.accept(emitter));

      final clean = DartFormatter().format(content.toString());

      return clean;
    } on FormatterException {
      print('Generated build script could not be parsed.\n'
          'This is likely caused by a misconfigured builder definition.');
      // TODO(mrgnhnt): throw custom exception
      throw Exception('Failed to generate build script');
    }
  }
}
