import 'package:revali_client/revali_client.dart';
import 'package:revali_client_null_primitive_return_types/revali_client_null_primitive_return_types.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group(
    'future',
    () {
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
        final response = await client.future.dataString();

        expect(response, null);
        verifyGetRequest('/api/future/data-string');
      });

      test('string', () async {
        final response = await client.future.string();

        expect(response, null);
        verifyGetRequest('/api/future/string');
      });

      test('bool', () async {
        final response = await client.future.boolean();

        expect(response, null);
        verifyGetRequest('/api/future/bool');
      });

      test('int', () async {
        final response = await client.future.integer();

        expect(response, null);
        verifyGetRequest('/api/future/int');
      });

      test('double', () async {
        final response = await client.future.dub();

        expect(response, null);
        verifyGetRequest('/api/future/double');
      });

      test('record', () async {
        final response = await client.future.record();

        expect(response, null);
        verifyGetRequest('/api/future/record');
      });

      test('named-record', () async {
        final response = await client.future.namedRecord();

        expect(response, null);
        verifyGetRequest('/api/future/named-record');
      });

      test('partial-record', () async {
        final response = await client.future.partialRecord();

        expect(response, null);
        verifyGetRequest('/api/future/partial-record');
      });

      test('list-of-records', () async {
        final response = await client.future.listOfRecords();

        expect(response, null);
        verifyGetRequest('/api/future/list-of-records');
      });

      test('list-of-strings', () async {
        final response = await client.future.listOfStrings();

        expect(response, null);
        verifyGetRequest('/api/future/list-of-strings');
      });

      test('list-of-maps', () async {
        final response = await client.future.listOfMaps();

        expect(response, null);
        verifyGetRequest('/api/future/list-of-maps');
      });

      test('map-string-dynamic', () async {
        final response = await client.future.map();

        expect(response, null);
        verifyGetRequest('/api/future/map-string-dynamic');
      });

      test('map-dynamic-dynamic', () async {
        final response = await client.future.dynamicMap();

        expect(response, null);
        verifyGetRequest('/api/future/map-dynamic-dynamic');
      });

      test('map-dynamic-dynamic-with-null', () async {
        final response = await client.future.dynamicMapWithNull();

        expect(response, {'foo': null});
        verifyGetRequest('/api/future/map-dynamic-dynamic-with-null');
      });

      test('set', () async {
        final response = await client.future.set();

        expect(response, null);
        verifyGetRequest('/api/future/set');
      });

      test('iterable', () async {
        final response = await client.future.iterable();

        expect(response, null);
        verifyGetRequest('/api/future/iterable');
      });

      test('bytes', () async {
        final response = await client.future.bytes();

        expect(response, null);
        verifyGetRequest('/api/future/bytes');
      });
    },
  );
}
