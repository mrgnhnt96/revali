import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('bind server e2e', () {
    late HttpServer httpServer;

    setUp(() async {
      httpServer = await createServer();
    });

    tearDown(() async {
      await httpServer.close(force: true);
    });

    test('binds dual-stack when host is localhost', () {
      expect(httpServer.address.type, InternetAddressType.IPv6);
      expect(httpServer.address.rawAddress, InternetAddress.anyIPv6.rawAddress);
    });

    test('accepts IPv4 loopback connections', () async {
      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.get(
        InternetAddress.loopbackIPv4.address,
        httpServer.port,
        '/api/get',
      );
      final response = await request.close();

      expect(response.statusCode, 200);

      final body = await response.transform(utf8.decoder).join();
      expect(jsonDecode(body), {'data': 'Hello world!'});
    });

    test('accepts IPv6 loopback connections', () async {
      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.get(
        InternetAddress.loopbackIPv6.address,
        httpServer.port,
        '/api/get',
      );
      final response = await request.close();

      expect(response.statusCode, 200);

      final body = await response.transform(utf8.decoder).join();
      expect(jsonDecode(body), {'data': 'Hello world!'});
    });
  });
}
