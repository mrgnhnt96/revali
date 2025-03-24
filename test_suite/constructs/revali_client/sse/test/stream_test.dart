import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_sse/revali_client_sse.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('stream', () {
    late TestServer server;
    late Server client;
    // ignore: unused_local_variable
    HttpRequest? request;
    HttpResponse? response;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient.sse(
          server,
          (req) => request = req,
          (resp) => response = resp,
        ),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyRequest(String method, String path) {
      expect(request?.method, method);
      expect(request?.url.path, path);
      expect(response?.statusCode, 200);
    }

    test('data-string', () async {
      final responses = await client.stream.dataString().toList();

      verifyRequest('GET', '/api/stream/data-string');

      expect(responses, ['Hello', 'world']);
    });

    test('string', () async {
      final responses = await client.stream.string().toList();

      verifyRequest('GET', '/api/stream/string');

      expect(responses, ['Hello', 'world']);
    });

    test('bool', () async {
      final responses = await client.stream.boolean().toList();

      verifyRequest('GET', '/api/stream/bool');

      expect(responses, [true, false]);
    });

    test('int', () async {
      final responses = await client.stream.integer().toList();

      verifyRequest('GET', '/api/stream/int');

      expect(responses, [1, 2]);
    });

    test('double', () async {
      final responses = await client.stream.dub().toList();

      verifyRequest('GET', '/api/stream/double');

      expect(responses, [1.0, 2.0]);
    });

    test('record', () async {
      final responses = await client.stream.record().toList();

      verifyRequest('GET', '/api/stream/record');

      expect(responses, [
        ('hello', 'world'),
        ('foo', 'bar'),
      ]);
    });

    test('named-record', () async {
      final responses = await client.stream.namedRecord().toList();

      verifyRequest('GET', '/api/stream/named-record');

      expect(responses, [
        (first: 'hello', second: 'world'),
        (first: 'foo', second: 'bar'),
      ]);
    });

    test('partial-record', () async {
      final responses = await client.stream.partialRecord().toList();

      verifyRequest('GET', '/api/stream/partial-record');

      expect(responses, [
        ('hello', second: 'world'),
        ('foo', second: 'bar'),
      ]);
    });

    test('list-of-records', () async {
      final responses = await client.stream.listOfRecords().toList();

      verifyRequest('GET', '/api/stream/list-of-records');

      expect(responses, [
        [
          ('hello', 'world'),
        ],
        [
          ('foo', 'bar'),
        ]
      ]);
    });

    test('list-of-strings', () async {
      final responses = await client.stream.listOfStrings().toList();

      verifyRequest('GET', '/api/stream/list-of-strings');

      expect(responses, [
        ['Hello'],
        ['world'],
      ]);
    });

    test('list-of-maps', () async {
      final responses = await client.stream.listOfMaps().toList();

      verifyRequest('GET', '/api/stream/list-of-maps');

      expect(responses, [
        [
          {'hello': 1},
        ],
        [
          {'foo': 2},
        ],
      ]);
    });

    test('map-string-dynamic', () async {
      final responses = await client.stream.map().toList();

      verifyRequest('GET', '/api/stream/map-string-dynamic');

      expect(responses, [
        {'hello': 1},
        {'foo': 2},
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final responses = await client.stream.dynamicMap().toList();

      verifyRequest('GET', '/api/stream/map-dynamic-dynamic');

      expect(responses, [
        {'true': true},
        {'false': false},
      ]);
    });

    test('set', () async {
      final responses = await client.stream.set().toList();

      verifyRequest('GET', '/api/stream/set');

      expect(responses, [
        {'Hello'},
        {'world'},
      ]);
    });

    test('iterable', () async {
      final responses = await client.stream.iterable().toList();

      verifyRequest('GET', '/api/stream/iterable');

      expect(responses, [
        ['Hello'],
        ['world'],
      ]);
    });

    test('bytes', () async {
      final responses = await client.stream.bytes().toList();

      verifyRequest('GET', '/api/stream/bytes');

      expect(responses, [
        utf8.encode('Hello'),
        utf8.encode('world'),
      ]);
    });
  });
}
