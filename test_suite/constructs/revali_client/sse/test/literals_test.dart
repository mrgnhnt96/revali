import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_sse/revali_client_sse.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literals', () {
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
      await client.literals.voidCall();

      verifyRequest('GET', '/api/literals/void');
    });

    test('data-string', () async {
      final responses = await client.literals.dataString().toList();

      verifyRequest('GET', '/api/literals/data-string');

      expect(responses, ['Hello world!']);
    });

    test('string', () async {
      final responses = await client.literals.string().toList();

      verifyRequest('GET', '/api/literals/string');

      expect(responses, ['Hello world!']);
    });

    test('bool', () async {
      final responses = await client.literals.boolean().toList();

      verifyRequest('GET', '/api/literals/bool');

      expect(responses, [true]);
    });

    test('int', () async {
      final responses = await client.literals.integer().toList();

      verifyRequest('GET', '/api/literals/int');

      expect(responses, [1]);
    });

    test('double', () async {
      final responses = await client.literals.dub().toList();

      verifyRequest('GET', '/api/literals/double');

      expect(responses, [1]);
    });

    test('record', () async {
      final responses = await client.literals.record().toList();

      verifyRequest('GET', '/api/literals/record');

      expect(responses, [('hello', 'world')]);
    });

    test('named-record', () async {
      final responses = await client.literals.namedRecord().toList();

      verifyRequest('GET', '/api/literals/named-record');

      expect(responses, [(first: 'hello', second: 'world')]);
    });

    test('partial-record', () async {
      final responses = await client.literals.partialRecord().toList();

      verifyRequest('GET', '/api/literals/partial-record');

      expect(responses, [('hello', second: 'world')]);
    });

    test('list-of-records', () async {
      final responses = await client.literals.listOfRecords().toList();

      verifyRequest('GET', '/api/literals/list-of-records');

      expect(responses, [
        [
          ('hello', 'world'),
        ]
      ]);
    });

    test('list-of-strings', () async {
      final responses = await client.literals.listOfStrings().toList();

      verifyRequest('GET', '/api/literals/list-of-strings');

      expect(responses, [
        ['Hello world!'],
      ]);
    });

    test('list-of-maps', () async {
      final responses = await client.literals.listOfMaps().toList();

      verifyRequest('GET', '/api/literals/list-of-maps');

      expect(responses, [
        [
          {'hello': 1},
        ]
      ]);
    });

    test('map-string-dynamic', () async {
      final responses = await client.literals.map().toList();

      verifyRequest('GET', '/api/literals/map-string-dynamic');

      expect(responses, [
        {'hello': 1},
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final responses = await client.literals.dynamicMap().toList();

      verifyRequest('GET', '/api/literals/map-dynamic-dynamic');

      expect(responses, [
        {'true': true},
      ]);
    });

    test('set', () async {
      final responses = await client.literals.set().toList();

      verifyRequest('GET', '/api/literals/set');

      expect(responses, [
        {'Hello world!'},
      ]);
    });

    test('iterable', () async {
      final responses = await client.literals.iterable().toList();

      verifyRequest('GET', '/api/literals/iterable');

      expect(responses, [
        ['Hello world!'],
      ]);
    });

    test('bytes', () async {
      final responses = await client.literals.bytes().toList();

      verifyRequest('GET', '/api/literals/bytes');

      expect(responses, [utf8.encode('Hello world!')]);
    });
  });
}
