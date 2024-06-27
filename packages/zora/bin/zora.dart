import 'dart:io';

import 'package:file/local.dart';
import 'package:zora/clis/zora_runner/zora_runner.dart';

void main(List<String> args) {
  _run(args);
}

Future<void> _run(List<String> args) async {
  final fs = LocalFileSystem();

  final runner = ZoraRunner(
    initialDirectory: fs.currentDirectory.path,
    fs: fs,
  );

  final result = await runner.run(args);

  exit(result);
}
