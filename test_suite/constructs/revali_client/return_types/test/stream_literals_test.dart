import 'dart:convert';

import 'package:http/http.dart';
import 'package:revali_client_return_types/revali_client_return_types.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group(
    'stream literals',
    () {
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
        final response = client.streamLiterals.dataString();

        expect(response, 'Hello world!');
        verifyGetRequest('/api/stream-literals/data-string');
      });

      test('string', () async {
        final response = client.streamLiterals.string();

        expect(response, 'Hello world!');
        verifyGetRequest('/api/stream-literals/string');
      });

      test('bool', () async {
        final response = client.streamLiterals.boolean();

        expect(response, true);
        verifyGetRequest('/api/stream-literals/bool');
      });

      test('int', () async {
        final response = client.streamLiterals.integer();

        expect(response, 1);
        verifyGetRequest('/api/stream-literals/int');
      });

      test('double', () async {
        final response = client.streamLiterals.dub();

        expect(response, 1);
        verifyGetRequest('/api/stream-literals/double');
      });

      test('record', () async {
        final response = client.streamLiterals.record();

        expect(response, ('hello', 'world'));
        verifyGetRequest('/api/stream-literals/record');
      });

      test('named-record', () async {
        final response = client.streamLiterals.namedRecord();

        expect(response, (first: 'hello', second: 'world'));
        verifyGetRequest('/api/stream-literals/named-record');
      });

      test('partial-record', () async {
        final response = client.streamLiterals.partialRecord();

        expect(response, ('hello', second: 'world'));
        verifyGetRequest('/api/stream-literals/partial-record');
      });

      test('list-of-records', () async {
        final response = client.streamLiterals.listOfRecords();

        expect(response, [('hello', 'world')]);
        verifyGetRequest('/api/stream-literals/list-of-records');
      });

      test('list-of-strings', () async {
        final response = client.streamLiterals.listOfStrings();

        expect(response, ['Hello world!']);
        verifyGetRequest('/api/stream-literals/list-of-strings');
      });

      test('list-of-maps', () async {
        final response = client.streamLiterals.listOfMaps();

        expect(response, [
          {'hello': 1},
        ]);
        verifyGetRequest('/api/stream-literals/list-of-maps');
      });

      test('map-string-dynamic', () async {
        final response = client.streamLiterals.map();

        expect(response, {'hello': 1});
        verifyGetRequest('/api/stream-literals/map-string-dynamic');
      });

      test('map-dynamic-dynamic', () async {
        final response = client.streamLiterals.dynamicMap();

        expect(response, {'true': true});
        verifyGetRequest('/api/stream-literals/map-dynamic-dynamic');
      });

      test('set', () async {
        final response = client.streamLiterals.set();

        expect(response, {'Hello world!'});
        verifyGetRequest('/api/stream-literals/set');
      });

      test('iterable', () async {
        final response = client.streamLiterals.iterable();

        expect(response, ['Hello world!']);
        verifyGetRequest('/api/stream-literals/iterable');
      });

      test('bytes', () async {
        final response = client.streamLiterals.bytes();

        expect(response, [utf8.encode('Hello world!')]);
        verifyGetRequest('/api/stream-literals/bytes');
      });
    },
  );
}
