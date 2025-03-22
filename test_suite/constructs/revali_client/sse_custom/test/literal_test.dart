import 'package:revali_client/revali_client.dart';
import 'package:revali_client_sse_custom/revali_client_sse_custom.dart';
import 'package:revali_client_sse_custom_test/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literals', () {
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
      final response = await client.literal.user();

      expect(response, const User(name: 'Hello world!'));
      verifyGetRequest('/api/literal/user');
    });

    test('list-of-users', () async {
      final response = await client.literal.listOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/literal/list-of-users');
    });

    test('set-of-users', () async {
      final response = await client.literal.setOfUsers();

      expect(response, {const User(name: 'Hello world!')});
      verifyGetRequest('/api/literal/set-of-users');
    });

    test('iterable-of-users', () async {
      final response = await client.literal.iterableOfUsers();

      expect(response, [const User(name: 'Hello world!')]);
      verifyGetRequest('/api/literal/iterable-of-users');
    });

    test('map-of-users', () async {
      final response = await client.literal.mapOfUsers();

      expect(response, {'user': const User(name: 'Hello world!')});
      verifyGetRequest('/api/literal/map-of-users');
    });

    test('record-of-users', () async {
      final response = await client.literal.recordOfUsers();

      expect(
        response,
        (name: 'Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/literal/record-of-users');
    });

    test('partial-record-of-users', () async {
      final response = await client.literal.partialRecordOfUsers();

      expect(
        response,
        ('Hello world!', user: const User(name: 'Hello world!')),
      );
      verifyGetRequest('/api/literal/partial-record-of-users');
    });
  });
}
