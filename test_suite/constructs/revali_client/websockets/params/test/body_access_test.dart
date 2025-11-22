import 'dart:async';

import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_params/revali_client_websocket_params.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('body access', () {
    late TestServer server;
    late Server client;

    setUp(() {
      server = TestServer();
      client = Server(websocket: TestWebSocket(server).connect);

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('future-string', () async {
      final stream = client.bodyParams.root(data: Stream.value('Hello'));

      final result = await stream.single;

      expect(result, 'Hello');
    });

    test('nested', () async {
      final stream = client.bodyParams.nested(
        body: Stream.value((data: 'Hello')),
      );

      final result = await stream.single;

      expect(result, 'Hello');
    });

    test('nested null', () async {
      final stream = client.bodyParams.nested(body: Stream.value((data: null)));

      final result = await stream.single;

      expect(result, 'no data');
    });

    test('multiple', () async {
      final stream = client.bodyParams.multiple(
        body: Stream.value((name: 'John', age: 20)),
      );

      final result = await stream.single;

      expect(result, 'John 20');
    });
  });
}
