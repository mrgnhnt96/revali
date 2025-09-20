// ignore_for_file: lines_longer_than_80_chars

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('multiple', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('should allow request when read middleware is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/multiple/read',
        headers: {'auth': 'sup dude'},
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'loz'});
      expect(response.headers['x-middleware'], ['loz']);
      expect(response.headers['x-auth'], isNull);
    });

    test('should proceed when annotations are as type reference', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/multiple/type-reference',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'loz'});
    });
  });
}
