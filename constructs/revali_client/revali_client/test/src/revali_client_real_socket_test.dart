import 'dart:async';
import 'dart:io' as io;

import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

/// Retry and timeout over a real TCP socket.
///
/// `revali_client_resilience_test.dart` drives these through a scripted
/// `HttpClient`, which proves the policy arithmetic but replaces the one part
/// most likely to be wrong: the transport. A fake `send` cannot refuse a
/// connection, cannot accept one and then say nothing, and cannot hand back
/// the `Stream<Uint8List>` that `package:http` actually returns — a bug that
/// already shipped once, where decoding an error body with
/// `transform(utf8.decoder)` turned *every* structured failure into a
/// TypeError.
///
/// So everything here goes through the default `HttpPackageClient` against a
/// real `HttpServer` on loopback: real sockets, real status lines, real
/// headers, real connection refusals.
///
/// Timing assertions are lower bounds only ("took at least the backoff"). A
/// lower bound cannot flake by running fast, and nothing here asserts an
/// upper bound or an ordering between independently scheduled things.

/// A real server that scripts its replies and counts what it received.
class _TestServer {
  _TestServer(this._server) {
    _server.listen(_handle);
  }

  static Future<_TestServer> start() async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);

    return _TestServer(server);
  }

  final io.HttpServer _server;

  /// One entry per request received: the method and path.
  final received = <String>[];

  /// Status codes to reply with, in order. The last is reused once exhausted.
  List<int> statuses = [200];

  /// Sent as `Retry-After` on any non-2xx reply, when set.
  String? retryAfter;

  /// When true the server accepts the connection and never answers.
  bool silent = false;

  int get port => _server.port;

  Future<void> _handle(io.HttpRequest request) async {
    received.add('${request.method} ${request.uri.path}');

    if (silent) {
      // Accepted and abandoned -- the failure a timeout exists for, and the
      // one a fake transport cannot produce.
      return;
    }

    final index = received.length - 1;
    final status = index < statuses.length ? statuses[index] : statuses.last;

    request.response.statusCode = status;

    if (status >= 300 && retryAfter != null) {
      request.response.headers.set('retry-after', retryAfter!);
    }

    request.response.write('{"data":"ok"}');
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}

/// A port with nothing listening, for connection-refused.
Future<int> _deadPort() async {
  final probe = await io.ServerSocket.bind(io.InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();

  return port;
}

RevaliClient clientAt(
  int port, {
  Duration? timeout,
  RetryPolicy retry = const RetryPolicy.none(),
}) => RevaliClient(
  storage: SessionStorage(),
  baseUrl: 'http://127.0.0.1:$port',
  timeout: timeout,
  retry: retry,
);

void main() {
  group('over a real socket', () {
    late _TestServer server;

    setUp(() async => server = await _TestServer.start());
    tearDown(() async => server.close());

    test('a real 503 is retried and the next attempt succeeds', () async {
      server.statuses = [503, 200];

      final response = await clientAt(
        server.port,
        retry: const RetryPolicy(initialDelay: Duration(milliseconds: 5)),
      ).request(method: 'GET', path: '/thing');

      expect(response.statusCode, 200);
      expect(server.received, ['GET /thing', 'GET /thing']);
    });

    test('a real 404 is not retried', () async {
      server.statuses = [404];

      await expectLater(
        clientAt(
          server.port,
          retry: const RetryPolicy(initialDelay: Duration(milliseconds: 5)),
        ).request(method: 'GET', path: '/missing'),
        throwsA(isA<ServerException>()),
      );

      expect(server.received, hasLength(1));
    });

    test('a real POST is not retried even on a retryable status', () async {
      server.statuses = [503, 200];

      await expectLater(
        clientAt(
          server.port,
          retry: const RetryPolicy(initialDelay: Duration(milliseconds: 5)),
        ).request(method: 'POST', path: '/orders'),
        throwsA(isA<ServerException>()),
      );

      // Retrying a POST that reached the server creates the resource twice.
      expect(server.received, ['POST /orders']);
    });

    test(
      'a real Retry-After delays the next attempt by at least that long',
      () async {
        server
          ..statuses = [503, 200]
          ..retryAfter = '1';

        final started = DateTime.now();

        final response = await clientAt(
          server.port,
          retry: const RetryPolicy(initialDelay: Duration(milliseconds: 1)),
        ).request(method: 'GET', path: '/thing');

        final elapsed = DateTime.now().difference(started);

        expect(response.statusCode, 200);

        // A lower bound: the 1ms backoff would have retried almost immediately,
        // so anything close to a second can only have come from the header.
        expect(
          elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 900)),
          reason:
              'Retry-After: 1 should have been honoured over the 1ms backoff',
        );
      },
    );

    test('a refused connection is retried, then reported', () async {
      final port = await _deadPort();

      final started = DateTime.now();

      await expectLater(
        clientAt(
          port,
          // maxAttempts defaults to 3; spelled out here would be redundant.
          retry: const RetryPolicy(initialDelay: Duration(milliseconds: 50)),
        ).request(method: 'GET', path: '/thing'),
        throwsA(isA<Object>()),
      );

      // Two backoffs between three attempts: 50ms + 100ms. A transport that
      // gave up immediately could not have taken this long.
      expect(
        DateTime.now().difference(started),
        greaterThanOrEqualTo(const Duration(milliseconds: 150)),
        reason: 'three attempts should have waited 50ms then 100ms',
      );
    });

    test('a peer that accepts and never answers hits the timeout', () async {
      server.silent = true;

      await expectLater(
        clientAt(
          server.port,
          timeout: const Duration(milliseconds: 300),
        ).request(method: 'GET', path: '/hang'),
        throwsA(isA<TimeoutException>()),
      );

      // It really did reach the server -- this is a timeout, not a refusal.
      expect(server.received, ['GET /hang']);
    });

    test('waits indefinitely when no timeout is set', () async {
      server.silent = true;

      final pending = clientAt(
        server.port,
      ).request(method: 'GET', path: '/hang');

      var settled = false;
      unawaited(
        pending.then(
          (_) => settled = true,
          onError: (_) {
            settled = true;
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(
        settled,
        isFalse,
        reason: 'without a timeout the request should still be waiting',
      );
    });
  });
}
