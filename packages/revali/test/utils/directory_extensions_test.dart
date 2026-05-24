import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizedChildDirectory', () {
    test('resolves nested paths on Windows-style paths', () {
      const fs = LocalFileSystem();
      final windows = p.Context(style: p.Style.windows);
      final stagingPath = windows.join(
        'D:',
        'a',
        'zonai',
        'zonai',
        'apps',
        'server',
        '.revali.staging',
      );
      final staging = fs.directory(stagingPath);

      final server = staging.sanitizedChildDirectory('server');
      expect(
        windows.normalize(server.path),
        windows.normalize(windows.join(stagingPath, 'server')),
      );

      final pubspec = server.sanitizedChildFile('pubspec.yaml');
      expect(
        windows.normalize(pubspec.path),
        windows.normalize(windows.join(stagingPath, 'server', 'pubspec.yaml')),
      );
    });
  });
}
