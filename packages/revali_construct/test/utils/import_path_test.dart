import 'dart:io';

import 'package:revali_construct/utils/import_path.dart';
import 'package:test/test.dart';

void main() {
  group('fileUriToRelativeImportPath', () {
    late Directory tempDir;
    late Directory originalCwd;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('import_path_test_');
      originalCwd = Directory.current;
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalCwd;
      tempDir.deleteSync(recursive: true);
    });

    test('returns posix relative paths from file URIs', () {
      final devApp = File('routes/apps/dev_app.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('');

      final uri = devApp.absolute.uri.toString();

      expect(fileUriToRelativeImportPath(uri), 'routes/apps/dev_app.dart');
      expect(fileUriToRelativeImportPath(uri), isNot(contains('\r')));
    });
  });
}
