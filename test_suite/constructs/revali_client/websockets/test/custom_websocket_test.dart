import 'dart:async';

import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websockets/revali_client_websockets.dart';
import 'package:revali_client_websockets_test/models/user.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() async {
  group(
    'custom websocket',
    () {
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
        final stream = client.customWebsocket
            .user(user: Stream.value(const User(name: 'John')));

        final result = await stream.single;

        expect(result, const User(name: 'John'));
      });
    },
  );
}
