import 'dart:io';

import 'package:revali_construct/utils/import_path.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:test/test.dart';

void main() {
  group('ServerImports', () {
    late Directory tempDir;
    late Directory originalCwd;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('server_imports_test_');
      originalCwd = Directory.current;
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalCwd;
      tempDir.deleteSync(recursive: true);
    });

    test('file URI resolves to posix relative path from project root', () {
      final devApp = File('routes/apps/dev_app.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('');

      final imports = ServerImports([devApp.absolute.uri.toString()]);

      expect(imports.paths.single, 'routes/apps/dev_app.dart');
      expect(imports.paths.single, isNot(contains(r'\')));
      expect(imports.paths.single, isNot(contains('\r')));
    });

    test('fileUriToRelativeImportPath never leaves backslashes', () {
      final devApp = File('routes/apps/dev_app.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('');

      expect(
        fileUriToRelativeImportPath(devApp.absolute.uri.toString()),
        'routes/apps/dev_app.dart',
      );
    });
  });
}
