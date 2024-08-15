import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:revali/dart_define/dart_define.dart';

mixin DartDefinesMixin on Command<int> {
  FileSystem get fs;

  DartDefine get defines {
    final argResults = this.argResults!;

    final defines = <String>[];
    final files = <String>[];

    if (argResults.wasParsed('dart-define')) {
      defines.addAll(argResults['dart-define'] as List<String>);
    }

    if (argResults.wasParsed('dart-define-from-file')) {
      files.addAll(argResults['dart-define-from-file'] as List<String>);
    }

    return DartDefine.fromFilesAndEntries(
      files: files,
      entries: defines,
      fs: fs,
    );
  }
}
