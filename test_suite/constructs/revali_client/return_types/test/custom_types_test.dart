import 'package:http/http.dart';
import 'package:revali_client_return_types/revali_client_return_types.dart';
import 'package:revali_client_return_types_test/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literals', () {
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
      final response = await client.customTypes.handle();

      expect(response, const User(name: 'Hello world!'));
      verifyGetRequest('/api/custom/types/user');
    });

    test('future-user', () async {
      final response = await client.customTypes.futureUser();

      expect(response, const User(name: 'Hello world!'));
      verifyGetRequest('/api/custom/types/future-user');
    });

    test('stream-user', () async {
      final response = await client.customTypes.streamUser().toList();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/custom/types/stream-user');
    });

    test('list-of-users', () async {
      final response = await client.customTypes.listOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/custom/types/list-of-users');
    });

    test('future-list-of-users', () async {
      final response = await client.customTypes.futureListOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/custom/types/future-list-of-users');
    });

    test('map-of-users', () async {
      final response = await client.customTypes.mapOfUsers();

      expect(response, {'user': const User(name: 'Hello world!')});
      verifyGetRequest('/api/custom/types/map-of-users');
    });

    test('future-map-of-users', () async {
      final response = await client.customTypes.futureMapOfUsers();

      expect(response, {'user': const User(name: 'Hello world!')});
      verifyGetRequest('/api/custom/types/future-map-of-users');
    });

    test('record-of-users', () async {
      final response = await client.customTypes.recordOfUsers();

      expect(
        response,
        (name: 'Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/custom/types/record-of-users');
    });

    test('partial-record-of-users', () async {
      final response = await client.customTypes.partialRecordOfUsers();

      expect(
        response,
        ('Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/custom/types/partial-record-of-users');
    });

    test('future-record-of-users', () async {
      final response = await client.customTypes.futureRecordOfUsers();

      expect(
        response,
        (name: 'Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/custom/types/future-record-of-users');
    });
  });
}
