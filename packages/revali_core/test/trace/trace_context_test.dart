import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

void main() {
  group('TraceContext.from', () {
    test('keeps the caller request id', () {
      expect(TraceContext.from(requestId: 'abc').requestId, 'abc');
    });

    test('generates an id when the caller sent none', () {
      final context = TraceContext.from();

      expect(context.requestId, hasLength(32));
      expect(context.requestId, matches(RegExp(r'^[0-9a-f]+$')));
    });

    test('treats a blank id as absent', () {
      // A proxy that always sets the header, sometimes to nothing, would
      // otherwise correlate every such request under the same empty id.
      expect(TraceContext.from(requestId: '   ').requestId, isNot('   '));
      expect(TraceContext.from(requestId: '').requestId, hasLength(32));
    });

    test('generates a different id each time', () {
      expect(
        TraceContext.from().requestId,
        isNot(TraceContext.from().requestId),
      );
    });

    test('carries traceparent verbatim', () {
      const parent = '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';

      expect(TraceContext.from(traceparent: parent).traceparent, parent);
    });

    test('never invents a traceparent', () {
      // A fabricated one is worse than none: a collector will stitch it into
      // the wrong trace rather than start a new one.
      expect(TraceContext.from().traceparent, isNull);
      expect(TraceContext.from(traceparent: '  ').traceparent, isNull);
    });
  });

  group('ambient context', () {
    test('is null outside a request', () {
      expect(TraceContext.current, isNull);
    });

    test('is reachable anywhere inside runWith', () {
      TraceContext.from(requestId: 'abc').runWith(() {
        expect(TraceContext.current?.requestId, 'abc');
      });
    });

    test('survives an async gap', () async {
      final context = TraceContext.from(requestId: 'abc');

      await context.runWith(() async {
        await Future<void>.delayed(Duration.zero);

        // The whole point: a handler that awaits still finds the context when
        // it finally makes its outbound call.
        expect(TraceContext.current?.requestId, 'abc');
      });
    });

    test('does not leak out of runWith', () {
      TraceContext.from(requestId: 'abc').runWith(() {});

      expect(TraceContext.current, isNull);
    });
  });

  group('outboundHeaders', () {
    test('always carries the request id', () {
      expect(TraceContext.from(requestId: 'abc').outboundHeaders(), {
        'X-Request-Id': 'abc',
      });
    });

    test('passes trace headers on when present', () {
      final context = TraceContext.from(
        requestId: 'abc',
        traceparent: '00-trace-span-01',
        tracestate: 'vendor=1',
      );

      expect(context.outboundHeaders(), {
        'X-Request-Id': 'abc',
        'traceparent': '00-trace-span-01',
        'tracestate': 'vendor=1',
      });
    });

    test('omits what the caller never sent', () {
      expect(
        TraceContext.from(requestId: 'abc').outboundHeaders().keys,
        ['X-Request-Id'],
      );
    });

    test('includes baggage added during the request', () {
      final context = TraceContext.from(requestId: 'abc');

      context.baggage['tenant'] = 'acme';

      expect(context.outboundHeaders()['baggage'], 'tenant=acme');
    });
  });

  group('baggage encoding', () {
    test('round-trips', () {
      final context = TraceContext.from(requestId: 'abc')
        ..baggage.addAll({'tenant': 'acme', 'cohort': 'b'});

      expect(
        TraceContext.decodeBaggage(context.encodedBaggage()),
        {'tenant': 'acme', 'cohort': 'b'},
      );
    });

    test('escapes delimiters so one entry cannot become two', () {
      final context = TraceContext.from(requestId: 'abc')
        ..baggage['note'] = 'a,b=c';

      final encoded = context.encodedBaggage();

      expect(encoded, isNot(contains('a,b=c')));
      expect(TraceContext.decodeBaggage(encoded), {'note': 'a,b=c'});
    });

    test('is null when empty', () {
      expect(TraceContext.from(requestId: 'abc').encodedBaggage(), isNull);
    });

    test('skips malformed entries rather than throwing', () {
      // This is input from another service; one bad entry must not fail the
      // request.
      expect(
        TraceContext.decodeBaggage('tenant=acme,garbage,=novalue,x=1'),
        {'tenant': 'acme', 'x': '1'},
      );
    });

    test('decodes an absent or blank header to nothing', () {
      expect(TraceContext.decodeBaggage(null), isEmpty);
      expect(TraceContext.decodeBaggage('  '), isEmpty);
    });
  });
}
