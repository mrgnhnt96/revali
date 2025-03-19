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
        final controller = StreamController<User>();
        Future<void>.delayed(const Duration(milliseconds: 100)).then(
          (_) async {
            controller.add(const User(name: 'John'));
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await controller.close();
          },
        ).ignore();

        final stream = client.customWebsocket.user(user: controller.stream);

        final result = await stream.first;

        expect(result, const User(name: 'John'));
      });
    },
    timeout: const Timeout(Duration(seconds: 100)),
  );
}
