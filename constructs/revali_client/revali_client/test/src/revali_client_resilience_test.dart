import 'dart:async';

import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

/// Replays a scripted sequence: an [HttpResponse] is returned, anything else
/// is thrown.
class ScriptedClient implements HttpClient {
  ScriptedClient(this._script, {this.interceptors = const []});

  final List<Object> _script;

  /// Every request the client actually sent, so a test can count attempts.
  final sent = <HttpRequest>[];

  @override
  final List<HttpInterceptor> interceptors;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    sent.add(request);

    final next = _script[sent.length - 1];

    return switch (next) {
      final HttpResponse response => response,
      final Exception failure => throw failure,
      _ => throw StateError('unexpected script entry: $next'),
    };
  }
}

/// Never answers, so a timeout is the only way out.
class SilentClient implements HttpClient {
  @override
  final List<HttpInterceptor> interceptors = [];

  @override
  Future<HttpResponse> send(HttpRequest request) =>
      Completer<HttpResponse>().future;
}

class Exploding implements HttpInterceptor {
  const Exploding();

  @override
  HttpResponse? onRequest(HttpRequest request) =>
      throw StateError('token refresh failed');

  @override
  HttpResponse? onResponse(HttpResponse response) => null;
}

class ShortCircuit implements HttpInterceptor {
  const ShortCircuit(this.response);

  final HttpResponse response;

  @override
  HttpResponse? onRequest(HttpRequest request) => response;

  @override
  HttpResponse? onResponse(HttpResponse response) => null;
}

HttpResponse responseFor(
  int status, {
  Map<String, String> headers = const {},
  Stream<List<int>>? stream,
}) => HttpResponse(
  request: HttpRequest(method: 'GET', url: Uri.parse('http://x.test/')),
  statusCode: status,
  headers: headers,
  stream: stream ?? const Stream.empty(),
  persistentConnection: false,
  reasonPhrase: null,
  contentLength: 0,
);

RevaliClient clientFor(
  HttpClient transport, {
  Duration? timeout,
  RetryPolicy retry = const RetryPolicy.none(),
}) => RevaliClient(
  storage: SessionStorage(),
  client: transport,
  baseUrl: 'http://x.test',
  timeout: timeout,
  retry: retry,
);

const fast = RetryPolicy(initialDelay: Duration(milliseconds: 1));

void main() {
  group('retry', () {
    test('is off by default', () async {
      final transport = ScriptedClient([responseFor(503), responseFor(200)]);

      await expectLater(
        clientFor(transport).request(method: 'GET', path: '/thing'),
        throwsA(isA<ServerException>()),
      );
      expect(transport.sent, hasLength(1));
    });

    test('sends again after a transient failure', () async {
      final transport = ScriptedClient([responseFor(503), responseFor(200)]);

      final response = await clientFor(
        transport,
        retry: fast,
      ).request(method: 'GET', path: '/thing');

      expect(response.statusCode, 200);
      expect(transport.sent, hasLength(2));
    });

    test('gives up after maxAttempts', () async {
      final transport = ScriptedClient([
        responseFor(503),
        responseFor(503),
        responseFor(503),
      ]);

      await expectLater(
        clientFor(
          transport,
          retry: fast,
        ).request(method: 'GET', path: '/thing'),
        throwsA(isA<ServerException>()),
      );
      expect(transport.sent, hasLength(3));
    });

    test('does not retry a POST', () async {
      final transport = ScriptedClient([responseFor(503), responseFor(200)]);

      await expectLater(
        clientFor(
          transport,
          retry: fast,
        ).request(method: 'POST', path: '/thing'),
        throwsA(isA<ServerException>()),
      );
      // Sending it twice could create the resource twice.
      expect(transport.sent, hasLength(1));
    });

    test('does not retry a 404', () async {
      final transport = ScriptedClient([responseFor(404), responseFor(200)]);

      await expectLater(
        clientFor(
          transport,
          retry: fast,
        ).request(method: 'GET', path: '/thing'),
        throwsA(isA<ServerException>()),
      );
      expect(transport.sent, hasLength(1));
    });

    test('retries a transport failure', () async {
      final transport = ScriptedClient([
        const SocketFailure(),
        responseFor(200),
      ]);

      final response = await clientFor(
        transport,
        retry: fast,
      ).request(method: 'GET', path: '/thing');

      expect(response.statusCode, 200);
      expect(transport.sent, hasLength(2));
    });

    test('rethrows a transport failure it will not retry', () async {
      final transport = ScriptedClient([const SocketFailure()]);

      await expectLater(
        clientFor(
          transport,
          retry: fast,
        ).request(method: 'POST', path: '/thing'),
        throwsA(isA<SocketFailure>()),
      );
      expect(transport.sent, hasLength(1));
    });

    test('drains a response it throws away', () async {
      var drained = false;
      final discarded = responseFor(
        503,
        stream:
            Stream<List<int>>.fromIterable([
              [1, 2, 3],
            ]).map((chunk) {
              drained = true;

              return chunk;
            }),
      );
      final transport = ScriptedClient([discarded, responseFor(200)]);

      await clientFor(
        transport,
        retry: fast,
      ).request(method: 'GET', path: '/thing');

      // An undrained response holds its socket, so a retry loop would leak
      // one connection per attempt.
      expect(drained, isTrue);
    });
  });

  group('timeout', () {
    test('gives up on a peer that never answers', () async {
      await expectLater(
        clientFor(
          SilentClient(),
          timeout: const Duration(milliseconds: 50),
        ).request(method: 'GET', path: '/thing'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('waits indefinitely when unset', () async {
      // Nothing to assert but the absence of a timeout, so this just has to
      // not complete quickly.
      final pending = clientFor(
        SilentClient(),
      ).request(method: 'GET', path: '/thing');

      var settled = false;
      unawaited(
        pending.then(
          (_) => settled = true,
          onError: (_) {
            settled = true;
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(settled, isFalse);
    });
  });

  group('interceptors', () {
    test('a throwing interceptor fails the request', () async {
      // The real transport, since interceptors are its behaviour. Exploding
      // throws before anything reaches the network.
      final inner = HttpPackageClient(interceptors: const [Exploding()]);

      // Previously swallowed, which put a half-prepared request on the wire
      // and surfaced as a puzzling 401 from the peer instead.
      await expectLater(
        inner.send(
          HttpRequest(method: 'GET', url: Uri.parse('http://x.test/')),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a returned response short-circuits the send', () async {
      final cached = responseFor(299);
      final inner = HttpPackageClient(interceptors: [ShortCircuit(cached)]);

      final response = await inner.send(
        HttpRequest(method: 'GET', url: Uri.parse('http://x.test/')),
      );

      // Never touched the network, which is what makes caching possible.
      expect(response.statusCode, 299);
    });
  });
}

/// Stands in for a connection-level failure.
class SocketFailure implements Exception {
  const SocketFailure();
}
