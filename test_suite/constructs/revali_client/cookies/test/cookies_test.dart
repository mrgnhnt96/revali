import 'package:revali_client/revali_client.dart';
import 'package:revali_client_cookies/revali_client_cookies.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('cookies', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;
    HttpResponse? response;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient(
          server,
          (req) => request = req,
          (resp) => response = resp,
        ),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyRequest(String path, {required String method}) {
      final req = request;
      expect(req?.url.path, path);
      expect(req?.body, isEmpty);
      expect(req?.method, method);
    }

    test('returns a successful response when cookie is required', () async {
      await client.storage.save('X-Auth', '123');

      await client.cookies.get();

      verifyRequest('/api/cookies/required', method: 'GET');
      final req = request!;
      expect(req.headers['cookie'], 'X-Auth=123');
    });

    test('should throw when cookie is not set', () async {
      expect(client.cookies.get(), throwsException);
    });

    test('should not throw when cookie is not set and is optional', () async {
      expect(client.cookies.getOptional(), completes);
    });

    test('should set new cookies after request', () async {
      await client.storage.save('X-Auth', '123');

      await client.cookies.lifecycle();

      verifyRequest('/api/cookies/lifecycle', method: 'GET');
      expect(await client.storage['X-Auth-Middleware'], '123');
      expect(await client.storage['X-Auth-Pre'], '456');
      expect(await client.storage['X-Auth-Post'], '789');
    });

    test('cookie should be assigned to empty string when provided', () async {
      await client.cookies.empty();

      verifyRequest('/api/cookies/empty', method: 'GET');
      final resp = response!;
      expect(resp.headers['set-cookie'], 'X-Auth=; ');
    });
  });
}
