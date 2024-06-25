import 'dart:io';

import 'package:file/local.dart';
import 'package:zora_gen/runner/zora_gen_runner.dart';
import 'package:zora_gen/zora_gen.dart';

void main(List<String> args) {
  _run(args);
}

Future<void> _run(List<String> args) async {
  final fs = LocalFileSystem();

  final runner = ZoraGenRunner(
    entryPointGenerator: EntrypointGenerator(
      initialDirectory: fs.currentDirectory.path,
      fs: fs,
    ),
  );

  final result = await runner.run(args);

  exit(result);
}
