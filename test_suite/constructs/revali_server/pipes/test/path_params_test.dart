import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('path', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/path/bool/true',
        headers: {
          'content-type': 'text/plain',
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });
  });
}
