import 'dart:async';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Awaits the summary — the half of an observation that only exists once the
/// request has finished.
class _Recorder implements Observer {
  final summaries = <RequestSummary>[];

  @override
  Future<void> see(ObservedRequest observed) async {
    summaries.add(await observed.summary);
  }
}

/// Uses only what is available at the start, and never awaits.
class _Immediate implements Observer {
  final seen = <String>[];

  @override
  void see(ObservedRequest observed) {
    seen.add(observed.request.method);
  }
}

class _Exploder implements Observer {
  @override
  Future<void> see(ObservedRequest observed) async =>
      throw StateError('exporter down');
}

class _ThrowsSynchronously implements Observer {
  @override
  void see(ObservedRequest observed) => throw StateError('bad wiring');
}

void main() {
  group('Observer', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve(List<Observer> observers) async {
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

    /// Observers are notified without being awaited, so give the event loop a
    /// turn before asserting.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test('summary reports how the request turned out', () async {
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

      expect(recorder.summaries.map((s) => s.routePath).toSet(), {
        '/users/:id',
      });
      expect(recorder.summaries.map((s) => s.path), ['/users/1', '/users/2']);
    });

    test('routePath is null when nothing matched', () async {
      final recorder = _Recorder();
      await serve([recorder]);

      await hit('/nope');
      await settle();

      expect(recorder.summaries.single.routePath, isNull);
      expect(recorder.summaries.single.statusCode, 404);
      expect(recorder.summaries.single.error, isNotNull);
    });

    test('an observer that never awaits still runs', () async {
      final immediate = _Immediate();
      await serve([immediate]);

      await hit('/users/7');
      await settle();

      expect(immediate.seen, ['GET']);
    });

    test('one observer can await while another does not', () async {
      final recorder = _Recorder();
      final immediate = _Immediate();
      await serve([recorder, immediate]);

      await hit('/users/7');
      await settle();

      expect(immediate.seen, ['GET']);
      expect(recorder.summaries, hasLength(1));
    });

    test('an async thrower does not stop the others', () async {
      final recorder = _Recorder();
      await serve([_Exploder(), recorder]);

      await hit('/users/7');
      await settle();

      expect(recorder.summaries, hasLength(1));
    });

    test('a synchronous thrower does not stop the others', () async {
      final recorder = _Recorder();
      await serve([_ThrowsSynchronously(), recorder]);

      await hit('/users/7');
      await settle();

      expect(recorder.summaries, hasLength(1));
    });

    test('awaiting the summary does not delay the response', () async {
      // The framework must not await observers -- if it did, an observer
      // waiting on the summary would deadlock the request producing it.
      await serve([_Recorder()]);

      await expectLater(
        hit('/users/7').timeout(const Duration(seconds: 5)),
        completes,
      );
    });
  });
}
