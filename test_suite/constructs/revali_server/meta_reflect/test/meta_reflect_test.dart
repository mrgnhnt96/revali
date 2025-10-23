// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('meta reflect', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test(
      'should return the user data without the private properties',
      () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/meta-reflect/user-data',
        );

        expect(response.statusCode, 200);
        expect(
          response.headers.contentType?.mimeType,
          ContentType.json.mimeType,
        );
        expect(response.body, {
          'data': {'name': 'Ganondorf'},
        });
      },
    );
  });
}
