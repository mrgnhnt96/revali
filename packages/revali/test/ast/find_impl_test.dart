import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/find/find_impl.dart';
import 'package:revali/utils/type_def/start_process.dart';
import 'package:test/test.dart';

void main() {
  group('FindImpl', () {
    test(
      'finds dart files in paths with spaces and apostrophes',
      () async {
        const fs = LocalFileSystem();
        const platform = LocalPlatform();
        final tempRoot = fs.systemTempDirectory.createTempSync('revali_find_');
        final workingDirectory = fs.directory(
          "${tempRoot.path}/Documents - Morgan's MacBook Pro/project",
        )..createSync(recursive: true);

        final dartFile = workingDirectory.childFile('example.dart')
          ..writeAsStringSync('void main() {}');

        const find = FindImpl(
          platform: platform,
          fs: fs,
          startProcess: processToDetails,
        );

        final files = await find.file(
          '*.dart',
          workingDirectory: workingDirectory.path,
        );

        expect(files, contains(dartFile.path));
      },
      skip: const LocalPlatform().isMacOS || const LocalPlatform().isLinux
          ? false
          : 'find is only used on Linux and macOS',
    );
  });
}
