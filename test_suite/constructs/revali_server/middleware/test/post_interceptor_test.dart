// ignore_for_file: lines_longer_than_80_chars

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('post interceptor', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('should add data to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/post/interceptor',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'sup dude'});
      expect(response.headers['x-middleware'], ['loz']);
    });

    test('should add custom data to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/post/interceptor/custom-header',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': 'sup dude',
      });
      expect(response.headers['x-loz'], ['oot']);
    });
  });
}
