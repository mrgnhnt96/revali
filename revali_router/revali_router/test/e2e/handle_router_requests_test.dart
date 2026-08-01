import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

void main() {
  group('handleRouterRequests', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve(Router router) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(handleRouterRequests(server, router, server.close));
    }

    setUp(() {
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('serves a route through the single-Find production path', () async {
      await serve(
        Router(
          routes: [
            Route(
              'ping',
              method: 'GET',
              handler: (context) async {
                context.response.body = 'pong';
              },
            ),
          ],
        ),
      );

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/ping'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, 'pong');
    });

    test('fail-closes with 500 when the handler throws', () async {
      await serve(
        Router(
          routes: [
            Route(
              'boom',
              method: 'GET',
              handler: (_) async {
                throw StateError('boom');
              },
            ),
          ],
        ),
      );

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/boom'),
      );
      final response = await request.close();

      expect(response.statusCode, HttpStatus.internalServerError);
      // Drain so the connection can close cleanly.
      await response.drain<void>();
    });
  });
}
