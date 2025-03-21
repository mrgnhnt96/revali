import 'dart:async';

import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_params/revali_client_websocket_params.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
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
        final stream = client.params.futureString(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('string', () async {
        final stream = client.params.string(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('stream-string', () async {
        final stream = client.params.streamString(
          message: Stream.value('Hello'),
        );

        final result = await stream.single;

        expect(result, 'Hello');
      });
    },
  );
}
