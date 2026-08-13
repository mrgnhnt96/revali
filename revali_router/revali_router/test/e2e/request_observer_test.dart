import 'dart:async';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Deliberately does **not** implement Observer: a listener that only wants
/// the completed-request summary must be registerable without a no-op `see`.
class _Recorder implements RequestObserver {
  final summaries = <RequestSummary>[];

  @override
  void onRequestComplete(RequestSummary summary) => summaries.add(summary);
}

/// Implements both, which must also work.
class _Both implements Observer, RequestObserver {
  final summaries = <RequestSummary>[];
  int seen = 0;

  @override
  Future<void> see(Request request, Future<Response> response) async => seen++;

  @override
  void onRequestComplete(RequestSummary summary) => summaries.add(summary);
}

class _Exploder implements RequestObserver {
  @override
  Future<void> onRequestComplete(RequestSummary summary) async =>
      throw StateError('exporter down');
}

/// Implements only Observer — must be skipped, not crashed on.
class _PlainObserver implements Observer {
  int seen = 0;

  @override
  Future<void> see(Request request, Future<Response> response) async => seen++;
}

void main() {
  group('RequestObserver', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve(List<RequestListener> observers) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        // Deliberately not debug: telemetry must work in production, where
        // the trace ring buffer is off.
        observers: observers,
        routes: [
          Route(
            'users',
            routes: [
              Route(
                ':id',
                method: 'GET',
                handler: (context) async {
                  context.response.body = 'user';
                },
              ),
            ],
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    Future<void> hit(String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      await (await request.close()).drain<void>();
    }

    setUp(() => client = HttpClient());

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    /// Observers are notified without being awaited, so give the microtask
    /// queue a turn before asserting.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test('reports a completed request', () async {
      final recorder = _Recorder();
      await serve([recorder]);

      await hit('/users/42');
      await settle();

      expect(recorder.summaries, hasLength(1));

      final summary = recorder.summaries.single;
      expect(summary.method, 'GET');
      expect(summary.path, '/users/42');
      expect(summary.statusCode, 200);
      expect(summary.error, isNull);
      expect(summary.duration, greaterThanOrEqualTo(Duration.zero));
    });

    test('labels with the registered route, not the concrete path', () async {
      // The whole point: /users/1 and /users/2 must share a label, or a
      // metrics backend gets one time series per id.
      final recorder = _Recorder();
      await serve([recorder]);

      await hit('/users/1');
      await hit('/users/2');
      await settle();

      expect(
        recorder.summaries.map((s) => s.routePath).toSet(),
        {'/users/:id'},
      );
      expect(recorder.summaries.map((s) => s.path), ['/users/1', '/users/2']);
    });

    test('routePath is null when nothing matched', () async {
      final recorder = _Recorder();
      await serve([recorder]);

      await hit('/nope');
      await settle();

      expect(recorder.summaries.single.routePath, isNull);
      expect(recorder.summaries.single.statusCode, 404);
    });

    test('carries the error for a failed response', () async {
      final recorder = _Recorder();
      await serve([recorder]);

      await hit('/nope');
      await settle();

      expect(recorder.summaries.single.error, isNotNull);
    });

    test('a throwing observer does not stop the others', () async {
      final recorder = _Recorder();
      await serve([_Exploder(), recorder]);

      await hit('/users/7');
      await settle();

      expect(recorder.summaries, hasLength(1));
    });

    test('a listener implementing both gets both callbacks', () async {
      final both = _Both();
      await serve([both]);

      await hit('/users/7');
      await settle();

      expect(both.seen, 1, reason: 'Observer.see still fires');
      expect(both.summaries, hasLength(1), reason: 'and so does the summary');
    });

    test('an observer that is not a RequestObserver is skipped', () async {
      final plain = _PlainObserver();
      await serve([plain]);

      await expectLater(hit('/users/7'), completes);
      await settle();

      expect(plain.seen, 1, reason: 'still gets the normal see() call');
    });
  });
}
