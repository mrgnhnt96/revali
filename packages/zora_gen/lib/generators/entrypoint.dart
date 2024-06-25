import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:zora_gen/parsers/constructs_handler.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class EntrypointGenerator {
  EntrypointGenerator({
    required this.initialDirectory,
    ConstructsHandler? constructHandler,
    required this.fs,
  }) : constructHandler = constructHandler ??
            ConstructsHandler(
              initialDirectory: initialDirectory,
              fs: fs,
            );

  final String initialDirectory;
  final ConstructsHandler constructHandler;
  final FileSystem fs;

  Future<File> generate() async {
    final root = await constructHandler.root;
    final constructs = await constructHandler.constructs(root);

    final needsNewKernel = await checkAssets(constructs, root);

    if (!needsNewKernel) {
      final kernel = root
          .childDirectory('.dart_tool')
          .childDirectory('zora')
          .childFile('zora.dart.dill');

      if (await kernel.exists()) {
        return kernel;
      }
    }

    final entrypointFile = await createEntrypoint(
      root,
      constructs: constructs,
    );

    final kernel = await compile(
      entrypointFile,
      fs,
      root: root,
    );

    return kernel;
  }

  Future<bool> checkAssets(
    List<ConstructYaml> constructs,
    Directory root,
  ) async {
    final assetsFile = root
        .childDirectory('.dart_tool')
        .childDirectory('zora')
        .childFile('zora.assets.json');

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

  Future<File> createEntrypoint(
    Directory root, {
    required List<ConstructYaml> constructs,
  }) async {
    final zoraDir = await root
        .childDirectory('.dart_tool')
        .childDirectory('zora')
        .create(recursive: true);

    final entrypointFile = zoraDir.childFile('zora.dart');

    if (await entrypointFile.exists()) {
      await entrypointFile.delete();
    }

    await entrypointFile.create();

    final entrypointContent = '''
import 'dart:isolate';
import 'dart:io';
import 'package:zora_gen/zora_gen.dart' as zora;
import 'package:zora_gen_core/zora_gen_core.dart';
import 'package:zora_shelf/zora_shelf.dart';

const constructs = <Construct>[
  ZoraShelfConstruct(),
];

const path = '${root.childDirectory('routes').path}';

void main(
  List<String> args, [
  SendPort? sendPort,
]) async {
  var result = await zora.run(
    args,
    constructs: constructs,
    path: path,
  );
  sendPort?.send(result);
  exitCode = result;
}''';

    await entrypointFile.writeAsString(entrypointContent);

    return entrypointFile;
  }

  Future<File> compile(
    File file,
    FileSystem fs, {
    required Directory root,
  }) async {
    final kernel = fs.file('${file.path}.dill');

    if (await kernel.exists()) {
      return kernel;
    }

    final packageJson =
        root.childDirectory('.dart_tool').childFile('package_config.json');

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
        file.path,
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

        // try {
        //   await file.delete();
        // } catch (e) {
        //   print('Failed to delete precompiled script: $e');
        // }
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
}
