import 'package:revali_client/revali_client.dart';
import 'package:revali_client_custom_return_types/revali_client_custom_return_types.dart';
import 'package:revali_client_custom_return_types_test/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('future', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

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
      final response = await client.future.user();

      expect(response, const User(name: 'Hello world!'));
      verifyGetRequest('/api/future/user');
    });

    test('list-of-users', () async {
      final response = await client.future.listOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/future/list-of-users');
    });

    test('set-of-users', () async {
      final response = await client.future.setOfUsers();

      expect(response, {const User(name: 'Hello world!')});
      verifyGetRequest('/api/future/set-of-users');
    });

    test('iterable-of-users', () async {
      final response = await client.future.iterableOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/future/iterable-of-users');
    });

    test('map-of-users', () async {
      final response = await client.future.mapOfUsers();

      expect(response, {'user': const User(name: 'Hello world!')});
      verifyGetRequest('/api/future/map-of-users');
    });

    test('record-of-users', () async {
      final response = await client.future.recordOfUsers();

      expect(
        response,
        (name: 'Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/future/record-of-users');
    });

    test('partial-record-of-users', () async {
      final response = await client.future.partialRecordOfUsers();

      expect(
        response,
        ('Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/future/partial-record-of-users');
    });
  });
}
