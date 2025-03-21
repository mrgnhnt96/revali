import 'package:http/http.dart';
import 'package:revali_client_custom_return_types/revali_client_custom_return_types.dart';
import 'package:revali_client_custom_return_types_test/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('stream', () {
    late TestServer server;
    late Server client;
    Request? request;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient(server, (req) => request = req),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyGetRequest(String path) {
      expect(request?.url.path, path);
      expect(request?.headers, isEmpty);
      expect(request?.body, isEmpty);
      expect(request?.method, 'GET');
    }

    test('user', () async {
      final response = await client.stream.user();

      expect(response, const User(name: 'Hello world!'));
      verifyGetRequest('/api/stream/user');
    });

    test('list-of-users', () async {
      final response = await client.stream.listOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/stream/list-of-users');
    });

    test('set-of-users', () async {
      final response = await client.stream.setOfUsers();

      expect(response, {const User(name: 'Hello world!')});
      verifyGetRequest('/api/stream/set-of-users');
    });

    test('iterable-of-users', () async {
      final response = await client.stream.iterableOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/stream/iterable-of-users');
    });

    test('map-of-users', () async {
      final response = await client.stream.mapOfUsers();

      expect(response, {'user': const User(name: 'Hello world!')});
      verifyGetRequest('/api/stream/map-of-users');
    });

    test('record-of-users', () async {
      final response = await client.stream.recordOfUsers();

      expect(
        response,
        (name: 'Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/stream/record-of-users');
    });

    test('partial-record-of-users', () async {
      final response = await client.stream.partialRecordOfUsers();

      expect(
        response,
        ('Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/stream/partial-record-of-users');
    });
  });
}
