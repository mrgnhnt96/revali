// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_sse/revali_client_sse.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('future', () {
    late TestServer server;
    late Server client;
    // ignore: unused_local_variable
    HttpRequest? request;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient.sse(server, (req) => request = req),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyRequest(String method, String path) {
      expect(request?.method, method);
      expect(request?.url.path, path);
    }

    test('void', () async {
      await client.future.voidCall();

      verifyRequest('GET', '/api/future/void');
    });

    test('data-string', () async {
      final responses = await client.future.dataString().toList();

      verifyRequest('GET', '/api/future/data-string');

      expect(responses, ['Hello world!']);
    });

    test('string', () async {
      final responses = await client.future.string().toList();

      verifyRequest('GET', '/api/future/string');

      expect(responses, ['Hello world!']);
    });

    test('bool', () async {
      final responses = await client.future.boolean().toList();

      verifyRequest('GET', '/api/future/bool');

      expect(responses, [true]);
    });

    test('int', () async {
      final responses = await client.future.integer().toList();

      verifyRequest('GET', '/api/future/int');

      expect(responses, [1]);
    });

    test('double', () async {
      final responses = await client.future.dub().toList();

      verifyRequest('GET', '/api/future/double');

      expect(responses, [1]);
    });

    test('record', () async {
      final responses = await client.future.record().toList();

      verifyRequest('GET', '/api/future/record');

      expect(responses, [('hello', 'world')]);
    });

    test('named-record', () async {
      final responses = await client.future.namedRecord().toList();

      verifyRequest('GET', '/api/future/named-record');

      expect(responses, [(first: 'hello', second: 'world')]);
    });

    test('partial-record', () async {
      final responses = await client.future.partialRecord().toList();

      verifyRequest('GET', '/api/future/partial-record');

      expect(responses, [('hello', second: 'world')]);
    });

    test('list-of-records', () async {
      final responses = await client.future.listOfRecords().toList();

      verifyRequest('GET', '/api/future/list-of-records');

      expect(responses, [
        [
          ('hello', 'world'),
        ]
      ]);
    });

    test('list-of-strings', () async {
      final responses = await client.future.listOfStrings().toList();

      verifyRequest('GET', '/api/future/list-of-strings');

      expect(responses, [
        ['Hello world!'],
      ]);
    });

    test('list-of-maps', () async {
      final responses = await client.future.listOfMaps().toList();

      verifyRequest('GET', '/api/future/list-of-maps');

      expect(responses, [
        [
          {'hello': 1},
        ]
      ]);
    });

    test('map-string-dynamic', () async {
      final responses = await client.future.map().toList();

      verifyRequest('GET', '/api/future/map-string-dynamic');

      expect(responses, [
        {'hello': 1},
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final responses = await client.future.dynamicMap().toList();

      verifyRequest('GET', '/api/future/map-dynamic-dynamic');

      expect(responses, [
        {'true': true},
      ]);
    });

    test('set', () async {
      final responses = await client.future.set().toList();

      verifyRequest('GET', '/api/future/set');

      expect(responses, [
        {'Hello world!'},
      ]);
    });

    test('iterable', () async {
      final responses = await client.future.iterable().toList();

      verifyRequest('GET', '/api/future/iterable');

      expect(responses, [
        ['Hello world!'],
      ]);
    });

    test('bytes', () async {
      final responses = await client.future.bytes().toList();

      verifyRequest('GET', '/api/future/bytes');

      expect(responses, [utf8.encode('Hello world!')]);
    });
  });
}
