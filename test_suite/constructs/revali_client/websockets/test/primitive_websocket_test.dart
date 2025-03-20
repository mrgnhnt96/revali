import 'dart:async';

import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websockets/revali_client_websockets.dart';
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

      test('future-string', () async {
        final stream = client.primitiveWebsocket.futureString(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('string', () async {
        final stream = client.primitiveWebsocket.string(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('stream-string', () async {
        final stream = client.primitiveWebsocket.streamString(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });
    },
  );
}
