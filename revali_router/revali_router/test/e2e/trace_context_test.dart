import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

void main() {
  group('trace context', () {
    late HttpServer server;
    late HttpClient client;

    /// Lets a test hold two requests inside their handlers at once.
    Completer<void>? gate;

    Future<void> serve() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        routes: [
          Route(
            'whoami',
            method: 'GET',
            handler: (context) async {
              final trace = TraceContext.current;

              context.response.body = {
                'requestId': trace?.requestId,
                'traceparent': trace?.traceparent,
                'tracestate': trace?.tracestate,
                'baggage': trace?.baggage,
              };
            },
          ),
          // Reads the context only after an await, and after both requests are
          // in flight, so a context that leaked between zones would show up.
          Route(
            'concurrent',
            method: 'GET',
            handler: (context) async {
              final before = TraceContext.current?.requestId;

              await gate!.future;

              context.response.body = {
                'before': before,
                'after': TraceContext.current?.requestId,
              };
            },
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    Future<Map<String, dynamic>> get(
      String path, {
      Map<String, String> headers = const {},
    }) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      headers.forEach(request.headers.set);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      return jsonDecode(body) as Map<String, dynamic>;
    }

    setUp(() {
      client = HttpClient();
      gate = Completer<void>();
    });

    tearDown(() async {
      if (gate?.isCompleted == false) {
        gate!.complete();
      }
      client.close(force: true);
      await server.close(force: true);
    });

    test('adopts the caller request id', () async {
      await serve();

      final body = await get(
        '/whoami',
        headers: {'X-Request-Id': 'from-caller'},
      );

      expect(body['requestId'], 'from-caller');
    });

    test('generates an id when the caller sent none', () async {
      await serve();

      expect(
        (await get('/whoami'))['requestId'],
        matches(RegExp(r'^[0-9a-f]{32}$')),
      );
    });

    test('carries traceparent and tracestate through', () async {
      await serve();

      final body = await get(
        '/whoami',
        headers: {
          'traceparent': '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba9-01',
          'tracestate': 'vendor=1',
        },
      );

      expect(
        body['traceparent'],
        '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba9-01',
      );
      expect(body['tracestate'], 'vendor=1');
    });

    test('decodes inbound baggage', () async {
      await serve();

      final body = await get(
        '/whoami',
        headers: {'baggage': 'tenant=acme,cohort=b'},
      );

      expect(body['baggage'], {'tenant': 'acme', 'cohort': 'b'});
    });

    test('is null for a request that never enters the router', () async {
      // Guards against the context being installed process-wide rather than
      // per request, which would look identical in every test above.
      expect(TraceContext.current, isNull);
    });

    test('keeps concurrent requests on their own contexts', () async {
      await serve();

      final first = get('/concurrent', headers: {'X-Request-Id': 'first'});
      final second = get('/concurrent', headers: {'X-Request-Id': 'second'});

      // Both handlers are now parked on the gate. Releasing them together is
      // what would expose a context shared between requests.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      gate!.complete();

      expect(await first, {'before': 'first', 'after': 'first'});
      expect(await second, {'before': 'second', 'after': 'second'});
    });
  });

  group('@RequestId', () {
    test('stamps the id the ambient context carries', () {
      final headers = HeadersImpl({});

      TraceContext.from(
        requestId: 'abc',
      ).runWith(() => const RequestId().ensureId(headers));

      // Two ids for one request would be worse than none.
      expect(headers['X-Request-Id'], 'abc');
    });

    test('leaves an id the caller already sent', () {
      final headers = HeadersImpl({
        'X-Request-Id': ['from-caller'],
      });

      TraceContext.from(
        requestId: 'abc',
      ).runWith(() => const RequestId().ensureId(headers));

      expect(headers['X-Request-Id'], 'from-caller');
    });

    test('still works outside a request, where there is no context', () {
      final headers = HeadersImpl({});

      const RequestId().ensureId(headers);

      expect(headers['X-Request-Id'], matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('honours a custom header name', () {
      final headers = HeadersImpl({});

      TraceContext.from(
        requestId: 'abc',
      ).runWith(() => const RequestId('X-Correlation-Id').ensureId(headers));

      expect(headers['X-Correlation-Id'], 'abc');
    });
  });
  group('across a hop', () {
    late HttpServer downstream;
    late HttpServer upstream;
    late HttpClient client;

    /// What the downstream service saw, so the test can compare the two ends.
    late Map<String, dynamic> seenByDownstream;

    setUp(() async {
      client = HttpClient();
      seenByDownstream = {};

      // Service B: records the context it was given.
      downstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final downstreamRouter = Router(
        routes: [
          Route(
            'inner',
            method: 'GET',
            handler: (context) async {
              final trace = TraceContext.current!;
              seenByDownstream = {
                'requestId': trace.requestId,
                'traceparent': trace.traceparent,
                'baggage': trace.baggage,
              };
              context.response.body = {'ok': true};
            },
          ),
        ],
      );
      unawaited(
        handleRouterRequests(downstream, downstreamRouter, downstream.close),
      );

      // Service A: calls B, forwarding whatever the ambient context holds.
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final upstreamRouter = Router(
        routes: [
          Route(
            'outer',
            method: 'GET',
            handler: (context) async {
              TraceContext.current!.baggage['tenant'] = 'acme';

              final outbound = await client.getUrl(
                Uri.parse('http://127.0.0.1:${downstream.port}/inner'),
              );
              // The one line an app writes. Everything else is ambient.
              TraceContext.current!.outboundHeaders().forEach(
                    outbound.headers.set,
                  );
              await (await outbound.close()).drain<void>();

              context.response.body = {
                'requestId': TraceContext.current!.requestId,
              };
            },
          ),
        ],
      );
      unawaited(handleRouterRequests(upstream, upstreamRouter, upstream.close));
    });

    tearDown(() async {
      client.close(force: true);
      await downstream.close(force: true);
      await upstream.close(force: true);
    });

    Future<Map<String, dynamic>> callUpstream(
      Map<String, String> headers,
    ) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${upstream.port}/outer'),
      );
      headers.forEach(request.headers.set);
      final response = await request.close();

      return jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
    }

    test('the request id survives the hop', () async {
      final body = await callUpstream({'X-Request-Id': 'end-to-end'});

      // Both services now name the same request. Before this, the second one
      // opened a fresh id and the two sets of logs could not be joined.
      expect(body['requestId'], 'end-to-end');
      expect(seenByDownstream['requestId'], 'end-to-end');
    });

    test('a generated id survives the hop too', () async {
      final body = await callUpstream({});

      expect(seenByDownstream['requestId'], body['requestId']);
      expect(body['requestId'], matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('traceparent reaches the far side unchanged', () async {
      const parent = '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';

      await callUpstream({'traceparent': parent});

      expect(seenByDownstream['traceparent'], parent);
    });

    test('baggage added mid-request reaches the far side', () async {
      await callUpstream({'X-Request-Id': 'with-baggage'});

      expect(seenByDownstream['baggage'], {'tenant': 'acme'});
    });
  });
}
