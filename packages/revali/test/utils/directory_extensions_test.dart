import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/package_config_resolution.dart';
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

  group('getPackageConfig', () {
    test('resolves workspace package config from member package', () async {
      const fs = LocalFileSystem();
      final member = fs.directory(
        p.join(p.current, '..', '..', 'small_test', 'app'),
      );
      final pubspec = member.childFile('pubspec.yaml');
      if (!pubspec.existsSync()) {
        return;
      }

      final packageConfig = await member.getPackageConfig();
      expect(packageConfig.existsSync(), isTrue);
      expect(
        packageConfig.path,
        contains('small_test${p.separator}.dart_tool'),
      );
      expect(
        packageConfig.path,
        isNot(contains('small_test${p.separator}app')),
      );
    });

    test('findPackageConfigPath walks up to workspace root', () async {
      const fs = LocalFileSystem();
      final member = fs.directory(
        p.join(p.current, '..', '..', 'small_test', 'app'),
      );
      final pubspec = member.childFile('pubspec.yaml');
      if (!pubspec.existsSync()) {
        return;
      }

      final resolvedPath = await findPackageConfigPath(member);
      expect(resolvedPath, isNotNull);
      expect(resolvedPath, contains('small_test${p.separator}.dart_tool'));
    });
  });
}
