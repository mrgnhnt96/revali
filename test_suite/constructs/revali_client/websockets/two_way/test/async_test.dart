import 'dart:async';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_two_way/revali_client_websocket_two_way.dart';
import 'package:revali_client_websocket_two_way_test/models/user.dart';
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
        websocket: TestWebSocket(server, (req) => request = req).connect,
        client: TestClient(server),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyGetRequest(String path) {
      expect(request?.url.path, path);

      expect(request?.headers['connection'], 'Upgrade');
      expect(request?.headers['upgrade'], 'websocket');
      expect(request?.headers['Sec-WebSocket-Version'], '13');

      expect(request?.headers['Sec-WebSocket-Key'], isNotEmpty);
      expect(request?.body, isEmpty);
      expect(request?.method, 'GET');
    }

    Stream<String> stringStream() async* {
      yield 'Hello world!';
      await Future<void>.delayed(Duration.zero);
    }

    Stream<User> userStream() async* {
      yield const User(name: 'John');
      await Future<void>.delayed(Duration.zero);
    }

    test('data-string', () async {
      final response = await client.async
          .dataString(data: stringStream())
          .toList();

      expect(response, ['Hello from the server', 'Hello world!']);
      verifyGetRequest('/api/async/data-string');
    });

    test('stream-string', () async {
      final response = await client.async
          .streamString(data: stringStream())
          .toList();

      expect(response, ['Hello from the server', 'Hello world!']);
      verifyGetRequest('/api/async/stream-string');
    });

    test('future-string', () async {
      final response = await client.async
          .futureString(data: stringStream())
          .toList();

      expect(response, ['Hello from the server', 'Hello world!']);
      verifyGetRequest('/api/async/future-string');
    });

    test('user', () async {
      final response = await client.async.user(data: userStream()).toList();

      expect(response, [const User(name: 'Jane'), const User(name: 'John')]);
      verifyGetRequest('/api/async/user');
    });

    test('stream-user', () async {
      final response = await client.async
          .streamUser(data: userStream())
          .toList();

      expect(response, [const User(name: 'Jane'), const User(name: 'John')]);
      verifyGetRequest('/api/async/stream-user');
    });

    test('future-user', () async {
      final response = await client.async
          .futureUser(data: userStream())
          .toList();

      expect(response, [const User(name: 'Jane'), const User(name: 'John')]);
      verifyGetRequest('/api/async/future-user');
    });
  });
}
