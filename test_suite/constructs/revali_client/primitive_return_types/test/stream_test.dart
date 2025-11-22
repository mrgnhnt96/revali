import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_primitive_return_types/revali_client_primitive_return_types.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('stream', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

    setUp(() {
      server = TestServer();

      client = Server(client: TestClient(server, (req) => request = req));

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

    test('data-string', () async {
      final response = await client.stream.dataString().toList();

      expect(response, ['Hello', 'world']);
      verifyGetRequest('/api/stream/data-string');
    });

    test('string', () async {
      final response = await client.stream.string().toList();

      expect(response, ['Hello', 'world']);
      verifyGetRequest('/api/stream/string');
    });

    test('bool', () async {
      final response = await client.stream.boolean().toList();

      expect(response, [true, false]);
      verifyGetRequest('/api/stream/bool');
    });

    test('int', () async {
      final response = await client.stream.integer().toList();

      expect(response, [1, 2]);
      verifyGetRequest('/api/stream/int');
    });

    test('double', () async {
      final response = await client.stream.dub().toList();

      expect(response, [1.0, 2.0]);
      verifyGetRequest('/api/stream/double');
    });

    test('record', () async {
      final response = await client.stream.record().toList();

      expect(response, [('hello', 'world'), ('foo', 'bar')]);
      verifyGetRequest('/api/stream/record');
    });

    test('named-record', () async {
      final response = await client.stream.namedRecord().toList();

      expect(response, [
        (first: 'hello', second: 'world'),
        (first: 'foo', second: 'bar'),
      ]);
      verifyGetRequest('/api/stream/named-record');
    });

    test('partial-record', () async {
      final response = await client.stream.partialRecord().toList();

      expect(response, [('hello', second: 'world'), ('foo', second: 'bar')]);
      verifyGetRequest('/api/stream/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.stream.listOfRecords().toList();

      expect(response, [
        [('hello', 'world')],
        [('foo', 'bar')],
      ]);
      verifyGetRequest('/api/stream/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.stream.listOfStrings().toList();

      expect(response, [
        ['Hello'],
        ['world'],
      ]);
      verifyGetRequest('/api/stream/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.stream.listOfMaps().toList();

      expect(response, [
        [
          {'hello': 1},
        ],
        [
          {'foo': 2},
        ],
      ]);
      verifyGetRequest('/api/stream/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.stream.map().toList();

      expect(response, [
        {'hello': 1},
        {'foo': 2},
      ]);
      verifyGetRequest('/api/stream/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.stream.dynamicMap().toList();

      expect(response, [
        {'true': true},
        {'false': false},
      ]);
      verifyGetRequest('/api/stream/map-dynamic-dynamic');
    });

    test('set', () async {
      final response = await client.stream.set().toList();

      expect(response, [
        {'Hello'},
        {'world'},
      ]);
      verifyGetRequest('/api/stream/set');
    });

    test('iterable', () async {
      final response = await client.stream.iterable().toList();

      expect(response, [
        ['Hello'],
        ['world'],
      ]);
      verifyGetRequest('/api/stream/iterable');
    });

    test('bytes', () async {
      final response = await client.stream.bytes().toList();
      final decoded = response.map(utf8.decode).toList();

      expect(decoded, ['Hello', 'world']);
      verifyGetRequest('/api/stream/bytes');
    });
  });
}
