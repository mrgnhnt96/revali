import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

void main() {
  group('graceful shutdown', () {
    late HttpServer server;
    late HttpClient client;
    late InFlightRequests inFlight;

    /// Releases the slow handler below.
    late Completer<void> release;

    /// Completes once a request has actually reached the handler, so tests
    /// never start shutting down before there is anything in flight.
    late Completer<void> reachedHandler;

    Future<void> serve() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      inFlight = InFlightRequests();

      final router = Router(
        routes: [
          Route(
            'slow',
            method: 'GET',
            handler: (context) async {
              if (!reachedHandler.isCompleted) {
                reachedHandler.complete();
              }
              await release.future;
              context.response.body = 'finished';
            },
          ),
        ],
      );

      unawaited(
        handleRouterRequests(
          server,
          router,
          server.close,
          inFlight: inFlight,
        ),
      );
    }

    setUp(() {
      client = HttpClient();
      release = Completer<void>();
      reachedHandler = Completer<void>();
    });

    tearDown(() async {
      if (!release.isCompleted) {
        release.complete();
      }
      client.close(force: true);
      await server.close(force: true);
    });

    test('an in-flight request still completes after shutdown starts',
        () async {
      await serve();

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/slow'),
      );
      final pending = request.close();

      await reachedHandler.future;
      expect(inFlight.length, 1);

      // Shutdown begins while the handler is mid-flight. Before in-flight
      // tracking existed this truncated the response.
      final shutdown = shutdownServer(
        server: server,
        inFlight: inFlight,
        timeout: const Duration(seconds: 10),
      );

      release.complete();

      final response = await pending;
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, 'finished');
      expect(await shutdown, isTrue, reason: 'should drain within timeout');
    });

    test('stops accepting new connections once shutdown starts', () async {
      await serve();

      final port = server.port;
      release.complete();

      expect(
        await shutdownServer(
          server: server,
          inFlight: inFlight,
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );

      await expectLater(
        client
            .getUrl(Uri.parse('http://127.0.0.1:$port/slow'))
            .then((r) => r.close()),
        throwsA(isA<SocketException>()),
      );
    });

    test('reports failure when in-flight requests outlast the timeout',
        () async {
      await serve();

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/slow'),
      );
      // The socket is force-closed in tearDown, so this never resolves
      // normally; swallow whatever it ends as.
      unawaited(request.close().then<void>((_) {}).catchError((Object _) {}));

      await reachedHandler.future;

      // The handler never releases before the deadline.
      expect(
        await shutdownServer(
          server: server,
          inFlight: inFlight,
          timeout: const Duration(milliseconds: 200),
        ),
        isFalse,
      );
    });

    test('runs onStopped after draining', () async {
      await serve();
      release.complete();

      var stoppedAfter = -1;

      await shutdownServer(
        server: server,
        inFlight: inFlight,
        timeout: const Duration(seconds: 5),
        onStopped: () async => stoppedAfter = inFlight.length,
      );

      expect(stoppedAfter, 0);
    });

    test('a throwing onStopped does not abort the shutdown', () async {
      await serve();
      release.complete();

      await expectLater(
        shutdownServer(
          server: server,
          inFlight: inFlight,
          timeout: const Duration(seconds: 5),
          onStopped: () async => throw StateError('pool close failed'),
        ),
        completion(isTrue),
      );
    });
  });

  group('drain delay', () {
    late HttpServer server;
    late HttpClient client;
    late InFlightRequests inFlight;

    Future<void> serve() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      inFlight = InFlightRequests();

      final router = Router(
        routes: [
          Route(
            'ping',
            method: 'GET',
            handler: (context) async {
              context.response.body = 'pong';
            },
          ),
          ...healthRoutes(
            settings: const HealthSettings(),
            isDraining: () => inFlight.isDraining,
          ),
        ],
      );

      unawaited(
        handleRouterRequests(server, router, server.close, inFlight: inFlight),
      );
    }

    Future<(int, String)> get(String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      final response = await request.close();

      return (
        response.statusCode,
        await response.transform(utf8.decoder).join(),
      );
    }

    setUp(() => client = HttpClient());

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('readiness fails while the server is still accepting', () async {
      await serve();

      expect((await get('/readyz')).$1, HttpStatus.ok);

      final shutdown = shutdownServer(
        server: server,
        inFlight: inFlight,
        timeout: const Duration(seconds: 5),
        drainDelay: const Duration(milliseconds: 500),
      );

      // This is the whole point of the delay. Closing the socket is invisible
      // to a load balancer, so there has to be a window where the probe says
      // "stop sending" while the server can still answer what is already on
      // its way. Without the delay these two assertions cannot both hold:
      // the second would fail with a SocketException.
      expect((await get('/readyz')).$1, HttpStatus.serviceUnavailable);
      expect(await get('/ping'), (HttpStatus.ok, 'pong'));

      expect(await shutdown, isTrue);
    });

    test('requests accepted during the delay are drained, not dropped',
        () async {
      await serve();

      final shutdown = shutdownServer(
        server: server,
        inFlight: inFlight,
        timeout: const Duration(seconds: 5),
        drainDelay: const Duration(milliseconds: 300),
      );

      final late = await get('/ping');

      expect(late, (HttpStatus.ok, 'pong'));
      expect(await shutdown, isTrue);
    });

    test('no delay by default — the socket closes at once', () async {
      await serve();

      final port = server.port;

      expect(
        await shutdownServer(
          server: server,
          inFlight: inFlight,
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );

      await expectLater(
        client
            .getUrl(Uri.parse('http://127.0.0.1:$port/readyz'))
            .then((r) => r.close()),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('InFlightRequests', () {
    test('drains immediately when nothing is in flight', () async {
      expect(
        await InFlightRequests().drain(const Duration(seconds: 1)),
        isTrue,
      );
    });

    test('stops counting a request once it completes', () async {
      final inFlight = InFlightRequests();
      final work = Completer<void>();

      inFlight.track(work.future);
      expect(inFlight.length, 1);

      work.complete();
      await Future<void>.delayed(Duration.zero);

      expect(inFlight.length, 0);
      expect(inFlight.isEmpty, isTrue);
    });

    test('a failed request does not make the drain give up', () async {
      final inFlight = InFlightRequests();
      final failing = Completer<void>();
      final healthy = Completer<void>();

      inFlight
        ..track(failing.future)
        ..track(healthy.future);

      failing.completeError(StateError('handler blew up'));
      final drained = inFlight.drain(const Duration(seconds: 5));

      await Future<void>.delayed(Duration.zero);
      healthy.complete();

      expect(await drained, isTrue);
    });

    test('marks itself draining', () async {
      final inFlight = InFlightRequests();
      expect(inFlight.isDraining, isFalse);

      await inFlight.drain(const Duration(seconds: 1));

      expect(inFlight.isDraining, isTrue);
    });
  });
}
