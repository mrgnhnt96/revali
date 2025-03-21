import 'dart:convert';

import 'package:http/http.dart';
import 'package:revali_client_primitive_return_types/revali_client_primitive_return_types.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('stream', () {
    late TestServer server;
    late Server client;
    Request? request;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient(server, (req) => request = req),
      );

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
      final response = await client.stream.dataString();

      expect(response, 'Hello world!');
      verifyGetRequest('/api/stream/data-string');
    });

    test('string', () async {
      final response = await client.stream.string();

      expect(response, 'Hello world!');
      verifyGetRequest('/api/stream/string');
    });

    test('bool', () async {
      final response = await client.stream.boolean();

      expect(response, true);
      verifyGetRequest('/api/stream/bool');
    });

    test('int', () async {
      final response = await client.stream.integer();

      expect(response, 1);
      verifyGetRequest('/api/stream/int');
    });

    test('double', () async {
      final response = await client.stream.dub();

      expect(response, 1);
      verifyGetRequest('/api/stream/double');
    });

    test('record', () async {
      final response = await client.stream.record();

      expect(response, ('hello', 'world'));
      verifyGetRequest('/api/stream/record');
    });

    test('named-record', () async {
      final response = await client.stream.namedRecord();

      expect(response, (first: 'hello', second: 'world'));
      verifyGetRequest('/api/stream/named-record');
    });

    test('partial-record', () async {
      final response = await client.stream.partialRecord();

      expect(response, ('hello', second: 'world'));
      verifyGetRequest('/api/stream/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.stream.listOfRecords();

      expect(response, [('hello', 'world')]);
      verifyGetRequest('/api/stream/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.stream.listOfStrings();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/stream/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.stream.listOfMaps();

      expect(response, [
        {'hello': 1},
      ]);
      verifyGetRequest('/api/stream/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.stream.map();

      expect(response, {'hello': 1});
      verifyGetRequest('/api/stream/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.stream.dynamicMap();

      expect(response, {'true': true});
      verifyGetRequest('/api/stream/map-dynamic-dynamic');
    });

    test('set', () async {
      final response = await client.stream.set();

      expect(response, {'Hello world!'});
      verifyGetRequest('/api/stream/set');
    });

    test('iterable', () async {
      final response = await client.stream.iterable();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/stream/iterable');
    });

    test('bytes', () async {
      final response = await client.stream.bytes().toList();

      expect(response, [utf8.encode('Hello world!')]);
      verifyGetRequest('/api/stream/bytes');
    });
  });
}
