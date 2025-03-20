import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_return_types/revali_client_websocket_return_types.dart';
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
        final stream = client.primitiveWebsocket.futureString();

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('string', () async {
        final stream = client.primitiveWebsocket.string();

        final result = await stream.single;

        expect(result, 'Hello');
      });

      test('stream-string', () async {
        final stream = client.primitiveWebsocket.streamString();

        final result = await stream.single;

        expect(result, 'Hello');
      });
    },
  );
}
