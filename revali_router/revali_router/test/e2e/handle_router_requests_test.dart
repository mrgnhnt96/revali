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

    test('serves a route under a dot-prefixed segment', () async {
      await serve(
        Router(
          routes: [
            Route(
              '.well-known',
              routes: [
                Route(
                  'security.txt',
                  method: 'GET',
                  handler: (context) async {
                    context.response.body = 'Contact: mailto:a@b.c';
                  },
                ),
              ],
            ),
          ],
        ),
      );

      final request = await client.getUrl(
        Uri.parse(
          'http://127.0.0.1:${server.port}/.well-known/security.txt',
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, 'Contact: mailto:a@b.c');
    });

    group('wildcard under an empty-path parent', () {
      for (final (wildcard, key) in [('*', '*'), ('*path', 'path')]) {
        Future<(int, String)> get(String path) async {
          final request = await client.getUrl(
            Uri.parse('http://127.0.0.1:${server.port}$path'),
          );
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();

          return (response.statusCode, body);
        }

        setUp(() async {
          await serve(
            Router(
              routes: [
                Route(
                  '',
                  routes: [
                    Route(
                      wildcard,
                      method: 'GET',
                      handler: (context) async {
                        final captured =
                            context.request.wildcardParameters[key];
                        context.response.body =
                            'wildcard:${captured?.join('/')}';
                      },
                    ),
                  ],
                ),
                Route(
                  'api',
                  routes: [
                    Route(
                      'status',
                      method: 'GET',
                      handler: (context) async {
                        context.response.body = 'status';
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        });

        for (final path in ['anything', 'a/b/c', '.well-known/x']) {
          test('$wildcard serves /$path', () async {
            final (status, body) = await get('/$path');

            expect(status, HttpStatus.ok);
            expect(body, 'wildcard:$path');
          });
        }

        test('$wildcard leaves the static sibling in charge', () async {
          final (status, body) = await get('/api/status');

          expect(status, HttpStatus.ok);
          expect(body, 'status');
        });
      }
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
