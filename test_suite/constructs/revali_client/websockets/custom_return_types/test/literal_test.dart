import 'dart:async';

import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_custom_return_types/revali_client_websocket_custom_return_types.dart';
import 'package:revali_client_websocket_custom_return_types_test/models/user.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() async {
  group('literal', () {
    late TestServer server;
    late Server client;

    setUp(() {
      server = TestServer();
      client = Server(
        websocket: TestWebSocket(server).connect,
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('user', () async {
      final stream =
          client.literal.user(user: Stream.value(const User(name: 'John')));

      final result = await stream.single;

      expect(result, const User(name: 'John'));
    });

    test('stream-user', () async {
      final stream = client.literal.streamUser(
        body: Stream.value((name: 'John', user: const User(name: 'John'))),
      );

      final result = await stream.single;

      expect(result, const User(name: 'John'));
    });

    test('future-user', () async {
      final stream = client.literal.futureUser(
        user: Stream.value(const User(name: 'John')),
      );

      final result = await stream.single;

      expect(result, const User(name: 'John'));
    });
  });
}
