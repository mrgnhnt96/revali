import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/models/swagger_settings.dart';
import 'package:revali_swagger/src/swagger_construct.dart';
import 'package:test/test.dart';

import '../helpers/swagger_e2e_helper.dart';

// Run `dart run tool/generate_goldens.dart` to regenerate golden files.
// Or run tests with `dart run --define=UPDATE_GOLDENS=true test <path>`.
const _updateGoldens = bool.fromEnvironment('UPDATE_GOLDENS');

void main() {
  late SwaggerE2eHelper helper;

  setUpAll(() async {
    helper = await SwaggerE2eHelper.create();
  });

  String goldenPath(String filename) => p.normalize(
    p.join(Directory.current.path, 'test', 'fixtures', 'golden', filename),
  );

  RevaliDirectory generate() {
    const context = RevaliContext(flavor: null, mode: Mode.debug);
    final settings = SwaggerSettings.fromJson({
      'title': 'Sample API',
      'version': '1.0.0',
    });
    return SwaggerConstruct(settings).generate(context, helper.server);
  }

  AnyFile fileWithExtension(RevaliDirectory result, String extension) {
    return result.files.firstWhere((f) => f.extension == extension);
  }

  group('output files', () {
    test('generates swagger.yaml and swagger.json', () {
      final result = generate();
      expect(result.files, hasLength(2));
      expect(
        result.files.map((f) => f.extension).toSet(),
        equals({'yaml', 'json'}),
      );
      for (final file in result.files) {
        expect(file.basename, 'swagger');
      }
    });

    test('YAML matches golden file', () async {
      final result = generate();
      final file = fileWithExtension(result, 'yaml');
      final golden = File(goldenPath('swagger.yaml'));

      if (_updateGoldens) {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(file.content);
        printOnFailure('Golden updated: ${golden.path}');
        return;
      }

      expect(
        golden.existsSync(),
        isTrue,
        reason:
            'Golden file not found. Run with -D '
            'UPDATE_GOLDENS=true to create it.',
      );

      expect(file.content, equals(golden.readAsStringSync()));
    });

    test('JSON matches golden file', () async {
      final result = generate();
      final file = fileWithExtension(result, 'json');
      final golden = File(goldenPath('swagger.json'));

      if (_updateGoldens) {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(file.content);
        printOnFailure('Golden updated: ${golden.path}');
        return;
      }

      expect(
        golden.existsSync(),
        isTrue,
        reason:
            'Golden file not found. Run with -D '
            'UPDATE_GOLDENS=true to create it.',
      );

      expect(file.content, equals(golden.readAsStringSync()));
    });
  });

  group('spec structure', () {
    late Map<String, dynamic> spec;

    setUp(() {
      final result = generate();
      final file = fileWithExtension(result, 'json');
      spec = _parseJson(file.content);
    });

    test('openapi version is 3.0.3', () {
      expect(spec['openapi'], '3.0.3');
    });

    test('info has correct title and version', () {
      final info = spec['info'] as Map<String, dynamic>;
      expect(info['title'], 'Sample API');
      expect(info['version'], '1.0.0');
    });

    test('GET /users is present', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths, contains('/users'));
      final usersPath = paths['/users'] as Map<String, dynamic>;
      expect(usersPath, contains('get'));
    });

    test('GET /users has summary from @ApiSummary', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      final getOp = (paths['/users'] as Map)['get'] as Map<String, dynamic>;
      expect(getOp['summary'], 'List all users');
    });

    test('GET /users has query param limit', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      final getOp = (paths['/users'] as Map)['get'] as Map<String, dynamic>;
      final parameters = getOp['parameters'] as List;
      final limitParam =
          parameters.firstWhere((p) => (p as Map)['name'] == 'limit')
              as Map<String, dynamic>;
      expect(limitParam['in'], 'query');
      expect(limitParam['required'], isFalse);
    });

    test('GET /users/{id} is present with path parameter', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths, contains('/users/{id}'));
      final op = (paths['/users/{id}'] as Map)['get'] as Map<String, dynamic>;
      final parameters = op['parameters'] as List;
      final idParam =
          parameters.firstWhere((p) => (p as Map)['name'] == 'id')
              as Map<String, dynamic>;
      expect(idParam['in'], 'path');
      expect(idParam['required'], isTrue);
    });

    test('POST /users has requestBody', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      final postOp = (paths['/users'] as Map)['post'] as Map<String, dynamic>;
      expect(postOp, contains('requestBody'));
      expect(postOp['responses'], contains('201'));
    });

    test('DELETE /users/{id} is hidden and not in spec', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      if (paths.containsKey('/users/{id}')) {
        final ops = paths['/users/{id}'] as Map;
        expect(ops, isNot(contains('delete')));
      }
    });

    test('hidden method types are not emitted in components/schemas', () {
      final schemas =
          (spec['components'] as Map<String, dynamic>)['schemas']
              as Map<String, dynamic>;
      expect(schemas, isNot(contains('SecretData')));
    });

    test('GET /users/search converts @Body to query param', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths, contains('/users/search'));
      final getOp =
          (paths['/users/search'] as Map)['get'] as Map<String, dynamic>;
      expect(getOp, isNot(contains('requestBody')));
      final parameters = getOp['parameters'] as List;
      final qParam =
          parameters.firstWhere((p) => (p as Map)['name'] == 'q')
              as Map<String, dynamic>;
      expect(qParam['in'], 'query');
      expect(qParam['required'], isTrue);
    });

    test('GET /users uses @ApiTag tag', () {
      final paths = spec['paths'] as Map<String, dynamic>;
      final getOp = (paths['/users'] as Map)['get'] as Map<String, dynamic>;
      final tags = getOp['tags'] as List;
      expect(tags, contains('users'));
    });

    test('User type appears in components/schemas', () {
      expect(spec, contains('components'));
      final schemas =
          (spec['components'] as Map<String, dynamic>)['schemas']
              as Map<String, dynamic>;
      expect(schemas, contains('User'));
    });
  });
}

Map<String, dynamic> _parseJson(String content) =>
    (jsonDecode(content) as Map).cast<String, dynamic>();
