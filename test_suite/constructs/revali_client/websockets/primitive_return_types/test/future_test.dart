import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_primitive_return_types/revali_client_websocket_primitive_return_types.dart';
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

    test('data-string', () async {
      final response = await client.future.dataString().toList();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/future/data-string');
    });

    test('string', () async {
      final response = await client.future.string().toList();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/future/string');
    });

    test('bool', () async {
      final response = await client.future.boolean().toList();

      expect(response, [true]);
      verifyGetRequest('/api/future/bool');
    });

    test('int', () async {
      final response = await client.future.integer().toList();

      expect(response, [1]);
      verifyGetRequest('/api/future/int');
    });

    test('double', () async {
      final response = await client.future.dub().toList();

      expect(response, [1.0]);
      verifyGetRequest('/api/future/double');
    });

    test('record', () async {
      final response = await client.future.record().toList();

      expect(response, [('hello', 'world')]);
      verifyGetRequest('/api/future/record');
    });

    test('named-record', () async {
      final response = await client.future.namedRecord().toList();

      expect(response, [
        (first: 'hello', second: 'world'),
      ]);
      verifyGetRequest('/api/future/named-record');
    });

    test('partial-record', () async {
      final response = await client.future.partialRecord().toList();

      expect(response, [
        ('hello', second: 'world'),
      ]);
      verifyGetRequest('/api/future/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.future.listOfRecords().toList();

      expect(response, [
        [
          ('hello', 'world'),
        ],
      ]);
      verifyGetRequest('/api/future/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.future.listOfStrings().toList();

      expect(response, [
        ['Hello world!'],
      ]);
      verifyGetRequest('/api/future/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.future.listOfMaps().toList();

      expect(response, [
        [
          {'hello': 1},
        ],
      ]);
      verifyGetRequest('/api/future/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.future.map().toList();

      expect(response, [
        {'hello': 1},
      ]);
      verifyGetRequest('/api/future/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.future.dynamicMap().toList();

      expect(response, [
        {'true': true},
      ]);
      verifyGetRequest('/api/future/map-dynamic-dynamic');
    });

    test('set', () async {
      final response = await client.future.set().toList();

      expect(response, [
        {'Hello world!'},
      ]);
      verifyGetRequest('/api/future/set');
    });

    test('iterable', () async {
      final response = await client.future.iterable().toList();

      expect(response, [
        ['Hello world!'],
      ]);
      verifyGetRequest('/api/future/iterable');
    });

    test('bytes', () async {
      final response = await client.future.bytes().toList();
      final decoded = response.map(utf8.decode).toList();

      expect(decoded, ['Hello world!']);
      verifyGetRequest('/api/future/bytes');
    });
  });
}
