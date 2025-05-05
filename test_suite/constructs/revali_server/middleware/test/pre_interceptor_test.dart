// ignore_for_file: lines_longer_than_80_chars

import 'package:revali_server_middleware_test/domain/user.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('pre interceptor', () {
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
        path: '/api/pre/interceptor',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'loz'});
    });

    test('should add auth token to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/pre/interceptor/auth',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'loz'});
    });

    test('should add user to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/pre/interceptor/auth-user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': const User(name: 'loz').toJson()});
    });

    test('should throw if user is not added to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/pre/interceptor/auth-user-throws',
      );

      expect(response.statusCode, 500);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: data, location: @data
'''),
      );
    });

    test('should add logger to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/pre/interceptor/logger',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'logged'});
    });

    test('should add custom data to the request', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/pre/interceptor/custom-data',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'loz': 'oot'},
      });
    });
  });
}
