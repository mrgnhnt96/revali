import 'package:analyzer/dart/analysis/results.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/ast/find/find_impl.dart';
import 'package:revali/utils/type_def/start_process.dart';
import 'package:test/test.dart';

void main() {
  group('Analyzer path-dependency refresh', () {
    late LocalFileSystem fs;
    late Directory temp;
    late Directory app;
    late Directory dep;
    late File appLib;
    late File depLib;
    late Analyzer analyzer;

    setUp(() async {
      fs = const LocalFileSystem();
      temp = fs.systemTempDirectory.createTempSync('revali_path_dep_');

      dep = fs.directory('${temp.path}/dep')..createSync();
      dep.childDirectory('lib').createSync();
      dep.childFile('pubspec.yaml').writeAsStringSync('''
name: dep
version: 0.0.1
environment:
  sdk: ">=3.8.0 <4.0.0"
''');
      depLib = dep.childFile('lib/dep.dart')
        ..writeAsStringSync('''
class Greeter {
  String greet() => 'v1';
}
''');

      app = fs.directory('${temp.path}/app')..createSync();
      app.childDirectory('lib').createSync();
      app.childFile('pubspec.yaml').writeAsStringSync('''
name: app
environment:
  sdk: ">=3.8.0 <4.0.0"
dependencies:
  dep:
    path: ../dep
''');
      appLib = app.childFile('lib/main.dart')
        ..writeAsStringSync('''
import 'package:dep/dep.dart';

String useDep() => Greeter().greet();
''');

      final depRootUri = Uri.directory(dep.path).toString();
      final appRootUri = Uri.directory(app.path).toString();
      app.childDirectory('.dart_tool').createSync(recursive: true);
      app.childFile('.dart_tool/package_config.json').writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "app",
      "rootUri": "$appRootUri",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "dep",
      "rootUri": "$depRootUri",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    }
  ],
  "generator": "revali_test"
}
''');

      analyzer = Analyzer(
        fs: fs,
        find: const FindImpl(
          platform: LocalPlatform(),
          fs: LocalFileSystem(),
          startProcess: processToDetails,
        ),
        platform: const LocalPlatform(),
        logger: Logger(level: Level.quiet),
      );

      await analyzer.initialize(root: app.path);
    });

    tearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    test('app context sees path-dep edits after refresh', () async {
      // Warm both contexts by resolving the app file that imports the dep.
      final before = await analyzer.analyze(appLib.path);
      expect(before, isNotEmpty);

      depLib.writeAsStringSync('''
class Greeter {
  String greet() => 'v2';
}
''');

      // Same path the file watcher would pass for an out-of-root change.
      await analyzer.refresh([depLib.path]);

      // Resolve via the *app* context (routes analysis path).
      final appContext = analyzer.analysisCollection.contextFor(appLib.path);
      final depParsed = appContext.currentSession.getParsedUnit(depLib.path);
      expect(depParsed, isA<ParsedUnitResult>());
      expect((depParsed as ParsedUnitResult).content, contains("'v2'"));
      expect(depParsed.content, isNot(contains("'v1'")));
    });
  });
}
