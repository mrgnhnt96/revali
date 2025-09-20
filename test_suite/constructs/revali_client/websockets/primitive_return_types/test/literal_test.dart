import 'package:revali_client/revali_client.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_client_websocket_primitive_return_types/revali_client_websocket_primitive_return_types.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literal', () {
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
      final response = await client.literals.dataString().toList();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/literals/data-string');
    });

    test('string', () async {
      final response = await client.literals.string().toList();

      expect(response, ['Hello world!']);
      verifyGetRequest('/api/literals/string');
    });

    test('bool', () async {
      final response = await client.literals.boolean().toList();

      expect(response, [true]);
      verifyGetRequest('/api/literals/bool');
    });

    test('int', () async {
      final response = await client.literals.integer().toList();

      expect(response, [1]);
      verifyGetRequest('/api/literals/int');
    });

    test('double', () async {
      final response = await client.literals.dub().toList();

      expect(response, [1.0]);
      verifyGetRequest('/api/literals/double');
    });

    test('record', () async {
      final response = await client.literals.record().toList();

      expect(response, [('hello', 'world')]);
      verifyGetRequest('/api/literals/record');
    });

    test('named-record', () async {
      final response = await client.literals.namedRecord().toList();

      expect(response, [(first: 'hello', second: 'world')]);
      verifyGetRequest('/api/literals/named-record');
    });

    test('partial-record', () async {
      final response = await client.literals.partialRecord().toList();

      expect(response, [('hello', second: 'world')]);
      verifyGetRequest('/api/literals/partial-record');
    });

    test('list-of-records', () async {
      final response = await client.literals.listOfRecords().toList();

      expect(response, [
        [('hello', 'world')],
      ]);
      verifyGetRequest('/api/literals/list-of-records');
    });

    test('list-of-strings', () async {
      final response = await client.literals.listOfStrings().toList();

      expect(response, [
        ['Hello world!'],
      ]);
      verifyGetRequest('/api/literals/list-of-strings');
    });

    test('list-of-maps', () async {
      final response = await client.literals.listOfMaps().toList();

      expect(response, [
        [
          {'hello': 1},
        ],
      ]);
      verifyGetRequest('/api/literals/list-of-maps');
    });

    test('map-string-dynamic', () async {
      final response = await client.literals.map().toList();

      expect(response, [
        {'hello': 1},
      ]);
      verifyGetRequest('/api/literals/map-string-dynamic');
    });

    test('map-dynamic-dynamic', () async {
      final response = await client.literals.dynamicMap().toList();

      expect(response, [
        {'true': true},
      ]);
      verifyGetRequest('/api/literals/map-dynamic-dynamic');
    });

    test('set', () async {
      final response = await client.literals.set().toList();

      expect(response, [
        {'Hello world!'},
      ]);
      verifyGetRequest('/api/literals/set');
    });

    test('iterable', () async {
      final response = await client.literals.iterable().toList();

      expect(response, [
        ['Hello world!'],
      ]);
      verifyGetRequest('/api/literals/iterable');
    });

    test('bytes', () async {
      final bytes = await client.literals.bytes().single;
      final decoded = String.fromCharCodes(bytes.toList());

      expect(decoded, 'Hello world!');
      verifyGetRequest('/api/literals/bytes');
    });
  });
}
