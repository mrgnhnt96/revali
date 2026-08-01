import 'package:file/memory.dart';
import 'package:revali/utils/kernel_cache.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:test/test.dart';

void main() {
  group('constructSetFingerprint', () {
    ConstructYaml yaml({
      required String packageName,
      required String packagePath,
      List<ConstructConfig> constructs = const [
        ConstructConfig(
          name: 'server',
          path: 'lib/server.dart',
          method: 'create',
          isServer: true,
        ),
      ],
    }) {
      return ConstructYaml(
        constructs: constructs,
        packagePath: packagePath,
        packageUri: 'package:$packageName/',
        packageName: packageName,
        packageRootUri: null,
      );
    }

    test('ignores absolute package paths', () {
      final a = constructSetFingerprint([
        yaml(packageName: 'revali_server', packagePath: '/tmp/a'),
      ], sdkVersion: '3.8.0');
      final b = constructSetFingerprint([
        yaml(packageName: 'revali_server', packagePath: '/other/b'),
      ], sdkVersion: '3.8.0');

      expect(a, equals(b));
    });

    test('differs when construct set differs', () {
      final serverOnly = constructSetFingerprint([
        yaml(packageName: 'revali_server', packagePath: '/x'),
      ], sdkVersion: '3.8.0');
      final withClient = constructSetFingerprint([
        yaml(packageName: 'revali_server', packagePath: '/x'),
        yaml(
          packageName: 'revali_client',
          packagePath: '/y',
          constructs: const [
            ConstructConfig(
              name: 'client',
              path: 'lib/client.dart',
              method: 'create',
            ),
          ],
        ),
      ], sdkVersion: '3.8.0');

      expect(serverOnly, isNot(equals(withClient)));
    });

    test('order of packages does not matter', () {
      final a = constructSetFingerprint([
        yaml(packageName: 'a', packagePath: '/a'),
        yaml(packageName: 'b', packagePath: '/b'),
      ], sdkVersion: '3.8.0');
      final b = constructSetFingerprint([
        yaml(packageName: 'b', packagePath: '/b'),
        yaml(packageName: 'a', packagePath: '/a'),
      ], sdkVersion: '3.8.0');

      expect(a, equals(b));
    });
  });

  group('resolveKernelCacheDir', () {
    test('uses REVALI_KERNEL_CACHE when set', () {
      // Covered indirectly via env in integration; MemoryFileSystem path:
      final fs = MemoryFileSystem();
      final root = fs.directory('/app')..createSync(recursive: true);
      // Without env override (tooling can't set Platform.environment), falls
      // through to project .dart_tool/revali_kernels.
      final dir = resolveKernelCacheDir(fs, root);
      expect(dir.path, endsWith('.dart_tool/revali_kernels'));
    });

    test('uses test_suite/.revali_kernel_cache under test_suite', () {
      final fs = MemoryFileSystem();
      final suite = fs.directory('/repo/test_suite')
        ..createSync(recursive: true);
      suite.childDirectory('constructs').createSync();
      final pkg =
          suite
              .childDirectory('constructs')
              .childDirectory('revali_server')
              .childDirectory('methods')
            ..createSync(recursive: true);

      final dir = resolveKernelCacheDir(fs, pkg);
      expect(dir.path, '/repo/test_suite/.revali_kernel_cache');
    });
  });

  group('outputsAreFresh', () {
    test('false when output missing', () {
      final fs = MemoryFileSystem();
      final root = fs.directory('/app')..createSync();
      final routes = root.childDirectory('routes')..createSync();
      routes.childFile('a.dart').writeAsStringSync('//');
      final output = root.childFile('out.dart');

      expect(
        outputsAreFresh(fs: fs, outputs: [output], inputDirs: [routes]),
        isFalse,
      );
    });

    test('true when outputs newer than inputs', () {
      final fs = MemoryFileSystem();
      final root = fs.directory('/app')..createSync();
      final routes = root.childDirectory('routes')..createSync();
      final source = routes.childFile('a.dart')..writeAsStringSync('//');
      final now = DateTime.now();
      source.setLastModifiedSync(now.subtract(const Duration(hours: 1)));
      final output = root.childFile('out.dart')
        ..writeAsStringSync('gen')
        ..setLastModifiedSync(now);

      expect(
        outputsAreFresh(fs: fs, outputs: [output], inputDirs: [routes]),
        isTrue,
      );
    });

    test('false when input newer than output', () {
      final fs = MemoryFileSystem();
      final root = fs.directory('/app')..createSync();
      final routes = root.childDirectory('routes')..createSync();
      final now = DateTime.now();
      final output = root.childFile('out.dart')
        ..writeAsStringSync('gen')
        ..setLastModifiedSync(now.subtract(const Duration(hours: 1)));
      routes.childFile('a.dart')
        ..writeAsStringSync('//')
        ..setLastModifiedSync(now);

      expect(
        outputsAreFresh(fs: fs, outputs: [output], inputDirs: [routes]),
        isFalse,
      );
    });
  });
}
