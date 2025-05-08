import 'package:revali_client/revali_client.dart';
import 'package:revali_client_primitive_return_types/revali_client_primitive_return_types.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literals', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

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

    test('void', () async {
      final call = client.literals.voidCall();

      expect(call, isA<Future<void>>());

      expect(call, completes);
      verifyGetRequest('/api/literals/void');
    });

    test('data-string', () async {
      final response = await client.literals.dataString();

      expect(response, 'Hello world!');
      verifyGetRequest('/api/literals/data-string');
    });

    test('string', () async {
      final response = await client.literals.string();

      expect(response, 'Hello world!');
      verifyGetRequest('/api/literals/string');
    });

    test('bool', () async {
      final response = await client.literals.boolean();

      expect(response, true);
      verifyGetRequest('/api/literals/bool');
    });

    test('int', () async {
      final response = await client.literals.integer();

      expect(response, 1);
      verifyGetRequest('/api/literals/int');
    });

    test('double', () async {
      final response = await client.literals.dub();

      expect(response, 1);
      verifyGetRequest('/api/literals/double');
    });

    test('record', () async {
      final response = await client.literals.record();

      expect(response, ('hello', 'world'));
      verifyGetRequest('/api/literals/record');
    });

    test('named-record', () async {
      final response = await client.literals.namedRecord();

      expect(response, (first: 'hello', second: 'world'));
      verifyGetRequest('/api/literals/named-record');
    });

    test('partial-record', () async {
      final response = await client.literals.partialRecord();

      expect(response, ('hello', second: 'world'));
      verifyGetRequest('/api/literals/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.literals.listOfRecords();

      expect(response, [('hello', 'world')]);
      verifyGetRequest('/api/literals/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.literals.listOfStrings();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/literals/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.literals.listOfMaps();

      expect(response, [
        {'hello': 1},
      ]);
      verifyGetRequest('/api/literals/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.literals.map();

      expect(response, {'hello': 1});
      verifyGetRequest('/api/literals/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.literals.dynamicMap();

      expect(response, {'true': true});
      verifyGetRequest('/api/literals/map-dynamic-dynamic');
    });

    test('set', () async {
      final response = await client.literals.set();

      expect(response, {'Hello world!'});
      verifyGetRequest('/api/literals/set');
    });

    test('iterable', () async {
      final response = await client.literals.iterable();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/literals/iterable');
    });

    test('bytes', () async {
      final response = await client.literals.bytes();
      final decoded = String.fromCharCodes(response.toList());

      expect(decoded, 'Hello world!');
      verifyGetRequest('/api/literals/bytes');
    });
  });
}
