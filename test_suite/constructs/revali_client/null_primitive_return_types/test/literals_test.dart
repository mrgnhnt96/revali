import 'package:revali_client/revali_client.dart';
import 'package:revali_client_null_primitive_return_types/revali_client_null_primitive_return_types.dart';
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

    test('data-string', () async {
      final response = await client.literals.dataString();

      expect(response, null);
      verifyGetRequest('/api/literals/data-string');
    });

    test('string', () async {
      final response = await client.literals.string();

      expect(response, null);
      verifyGetRequest('/api/literals/string');
    });

    test('bool', () async {
      final response = await client.literals.boolean();

      expect(response, null);
      verifyGetRequest('/api/literals/bool');
    });

    test('int', () async {
      final response = await client.literals.integer();

      expect(response, null);
      verifyGetRequest('/api/literals/int');
    });

    test('double', () async {
      final response = await client.literals.dub();

      expect(response, null);
      verifyGetRequest('/api/literals/double');
    });

    test('record', () async {
      final response = await client.literals.record();

      expect(response, null);
      verifyGetRequest('/api/literals/record');
    });

    test('named-record', () async {
      final response = await client.literals.namedRecord();

      expect(response, null);
      verifyGetRequest('/api/literals/named-record');
    });

    test('partial-record', () async {
      final response = await client.literals.partialRecord();

      expect(response, null);
      verifyGetRequest('/api/literals/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.literals.listOfRecords();

      expect(response, null);
      verifyGetRequest('/api/literals/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.literals.listOfStrings();

      expect(response, null);
      verifyGetRequest('/api/literals/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.literals.listOfMaps();

      expect(response, null);
      verifyGetRequest('/api/literals/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.literals.map();

      expect(response, null);
      verifyGetRequest('/api/literals/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.literals.dynamicMap();

      expect(response, null);
      verifyGetRequest('/api/literals/map-dynamic-dynamic');
    });

    test('map-dynamic-dynamic-with-null', () async {
      final response = await client.literals.dynamicMapWithNull();

      expect(response, {'foo': null});
      verifyGetRequest('/api/literals/map-dynamic-dynamic-with-null');
    });

    test('set', () async {
      final response = await client.literals.set();

      expect(response, null);
      verifyGetRequest('/api/literals/set');
    });

    test('iterable', () async {
      final response = await client.literals.iterable();

      expect(response, null);
      verifyGetRequest('/api/literals/iterable');
    });

    test('bytes', () async {
      final response = await client.literals.bytes();

      expect(response, null);
      verifyGetRequest('/api/literals/bytes');
    });
  });
}
