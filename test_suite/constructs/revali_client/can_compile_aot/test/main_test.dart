import 'package:can_compile_aot/can_compile_aot.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../.revali/server/server.dart';

void main() {
  group('can compile aot', () {
    late FileSystem fs;

    setUp(() {
      fs = const LocalFileSystem();
    });

    test('can compile aot', () async {
      final server = TestServer();
      final client = CanCompileAotServer(client: TestClient(server));

      expect(client, isA<CanCompileAotServer>());

      createServer(server).ignore();

      await server.close();
    });

    test('pubspec does not have websocket imports', () async {
      final pubspec = fs.file(
        fs.path.join(
          fs.currentDirectory.path,
          '.revali',
          'revali_client',
          'pubspec.yaml',
        ),
      );

      final content = loadYaml(await pubspec.readAsString()) as YamlMap;

      final dependencies = content['dependencies'] as YamlMap;

      expect(dependencies, hasLength(2));
      expect(dependencies.keys, ['http', 'revali_client']);
    });

    test('excluded controller is excluded', () async {
      final dynamic client = CanCompileAotServer(
        client: TestClient(TestServer()),
      );

      // ignore: avoid_dynamic_calls
      expect(() => client.excluded, throwsA(isA<NoSuchMethodError>()));
    });

    test('web socket method is excluded', () async {
      final client = CanCompileAotServer(client: TestClient(TestServer()));
      final dynamic webSocket = client.webSocket;

      // ignore: avoid_dynamic_calls
      expect(() => webSocket.user, throwsA(isA<NoSuchMethodError>()));
    });
  });
}
