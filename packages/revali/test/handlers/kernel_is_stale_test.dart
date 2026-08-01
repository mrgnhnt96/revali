import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:test/test.dart';

void main() {
  group('ConstructEntrypointHandler.kernelIsStale', () {
    late LocalFileSystem fs;
    late Directory tempRoot;
    late Directory projectRoot;
    late ConstructEntrypointHandler handler;

    setUp(() {
      fs = const LocalFileSystem();
      tempRoot = fs.systemTempDirectory.createTempSync('revali_kernel_');
      projectRoot = fs.directory('${tempRoot.path}/app')
        ..createSync(recursive: true);
      projectRoot.childFile('pubspec.yaml').writeAsStringSync('''
name: kernel_stale_fixture
environment:
  sdk: ">=3.8.0 <4.0.0"
''');

      handler = ConstructEntrypointHandler(
        initialDirectory: projectRoot.path,
        fs: fs,
        logger: Logger(level: Level.quiet),
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    ConstructYaml constructAt(String packagePath) {
      return ConstructYaml(
        constructs: const [
          ConstructConfig(
            name: 'fake',
            path: 'lib/fake.dart',
            method: 'create',
          ),
        ],
        packagePath: packagePath,
        packageUri: 'package:fake/',
        packageName: 'fake',
        packageRootUri: null,
      );
    }

    Future<File> writeKernel({required DateTime modified}) async {
      final kernel = await projectRoot.getInternalRevaliFile(
        ConstructEntrypointHandler.kernelFile,
      );
      kernel
        ..createSync(recursive: true)
        ..writeAsStringSync('dill')
        ..setLastModifiedSync(modified);
      return kernel;
    }

    test('missing kernel is stale', () async {
      final constructPkg = fs.directory('${tempRoot.path}/construct')
        ..createSync();
      constructPkg.childDirectory('lib').createSync();
      constructPkg.childFile('lib/a.dart').writeAsStringSync('void a() {}');

      final stale = await handler.kernelIsStale([
        constructAt(constructPkg.path),
      ], projectRoot);

      expect(stale, isTrue);
    });

    test('construct lib newer than kernel is stale', () async {
      final now = DateTime.now();
      await writeKernel(modified: now.subtract(const Duration(hours: 1)));

      final constructPkg = fs.directory('${tempRoot.path}/construct')
        ..createSync();
      final lib = constructPkg.childDirectory('lib')..createSync();
      lib.childFile('a.dart')
        ..writeAsStringSync('void a() {}')
        ..setLastModifiedSync(now);

      final stale = await handler.kernelIsStale([
        constructAt(constructPkg.path),
      ], projectRoot);

      expect(stale, isTrue);
    });

    test('sources older than kernel are not stale', () async {
      final now = DateTime.now();
      await writeKernel(modified: now);

      final constructPkg = fs.directory('${tempRoot.path}/construct')
        ..createSync();
      final lib = constructPkg.childDirectory('lib')..createSync();
      lib.childFile('a.dart')
        ..writeAsStringSync('void a() {}')
        ..setLastModifiedSync(now.subtract(const Duration(hours: 1)));

      final stale = await handler.kernelIsStale([
        constructAt(constructPkg.path),
      ], projectRoot);

      expect(stale, isFalse);
    });

    test('revali_* path package newer than kernel is stale', () async {
      final now = DateTime.now();
      await writeKernel(modified: now.subtract(const Duration(hours: 1)));

      final constructPkg = fs.directory('${tempRoot.path}/construct')
        ..createSync();
      final constructLib = constructPkg.childDirectory('lib')..createSync();
      constructLib.childFile('a.dart')
        ..writeAsStringSync('void a() {}')
        ..setLastModifiedSync(now.subtract(const Duration(hours: 2)));

      final revaliPkg = fs.directory('${tempRoot.path}/revali_router')
        ..createSync();
      final revaliLib = revaliPkg.childDirectory('lib')..createSync();
      revaliLib.childFile('router.dart')
        ..writeAsStringSync('void router() {}')
        ..setLastModifiedSync(now);

      final dartTool = projectRoot.childDirectory('.dart_tool')..createSync();
      dartTool.childFile('package_config.json').writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "revali_router",
      "rootUri": "${revaliPkg.uri}",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    }
  ]
}
''');

      final stale = await handler.kernelIsStale([
        constructAt(constructPkg.path),
      ], projectRoot);

      expect(stale, isTrue);
    });
  });
}
