import 'dart:async';

import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

/// A dependency built per message, so scoping and disposal are observable.
class Session implements Disposable {
  Session(this.id);

  static int built = 0;
  static final disposed = <int>[];

  final int id;

  @override
  Future<void> dispose() async => disposed.add(id);
}

void main() {
  late InMemoryBroker broker;
  late ConsumerRegistry registry;

  setUp(() {
    Session.built = 0;
    Session.disposed.clear();
    broker = InMemoryBroker();
    registry = ConsumerRegistry(broker: broker);
  });

  group('delivery', () {
    test('a consumer receives what was published', () async {
      final seen = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );
      await broker.publish('orders', 'placed');

      expect(seen, ['placed']);
    });

    test('a message published before anyone listened is not lost', () async {
      await broker.publish('orders', 'early');

      final seen = <String>[];
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );

      expect(seen, ['early']);
    });

    test('one group shares the work', () async {
      final first = <String>[];
      final second = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => first.add(m.payload),
      );
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => second.add(m.payload),
      );

      for (var i = 0; i < 8; i++) {
        await broker.publish('orders', '$i');
      }

      // Every message went to exactly one member.
      expect(first.length + second.length, 8);
      expect({...first, ...second}, hasLength(8));
    });

    test('separate groups each get a copy', () async {
      final billing = <String>[];
      final shipping = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => billing.add(m.payload),
      );
      await registry.consume(
        'orders',
        group: 'shipping',
        onMessage: (m) => shipping.add(m.payload),
      );

      await broker.publish('orders', 'placed');

      // This is what lets a fourth service react to an event without the
      // publisher being changed.
      expect(billing, ['placed']);
      expect(shipping, ['placed']);
    });

    test('a topic nobody subscribed to reaches no one', () async {
      final seen = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );
      await broker.publish('shipments', 'dispatched');

      expect(seen, isEmpty);
    });

    test('a throwing handler does not take down the consumer', () async {
      final seen = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) {
          if (m.payload == 'bad') {
            throw StateError('boom');
          }
          seen.add(m.payload);
        },
      );

      await broker.publish('orders', 'bad');
      await broker.publish('orders', 'good');

      expect(seen, ['good']);
    });
  });

  group('trace continuity', () {
    test('a message carries its own trace context', () async {
      String? seen;

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => seen = TraceContext.current?.requestId,
      );

      await broker.publish(
        'orders',
        'placed',
        headers: {'X-Request-Id': 'from-the-request'},
      );

      // The event was published during a request and handled later, possibly
      // in another process; without this the two are unjoinable in logs.
      expect(seen, 'from-the-request');
    });

    test('generates an id when the publisher sent none', () async {
      String? seen;

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => seen = TraceContext.current?.requestId,
      );
      await broker.publish('orders', 'placed');

      expect(seen, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('carries baggage across the hop', () async {
      Map<String, String>? seen;

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => seen = TraceContext.current?.baggage,
      );
      await broker.publish(
        'orders',
        'placed',
        headers: {'baggage': 'tenant=acme'},
      );

      expect(seen, {'tenant': 'acme'});
    });

    test('does not leak the context outside the handler', () async {
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );
      await broker.publish('orders', 'placed');

      expect(TraceContext.current, isNull);
    });
  });

  group('dependency scoping', () {
    test('builds a scoped dependency once per message', () async {
      final di = DIImpl()
        ..registerRequestScoped(() => Session(++Session.built));
      final scoped = ConsumerRegistry(
        broker: broker,
        di: DIHandler(di)..finishRegistration(),
      );

      final ids = <int>[];
      await scoped.consume(
        'orders',
        group: 'billing',
        onMessage: (_) {
          // Resolved twice: the same message must see the same instance.
          final a = RequestScopedDI.current.get<Session>();
          final b = RequestScopedDI.current.get<Session>();
          expect(identical(a, b), isTrue);
          ids.add(a.id);
        },
      );

      await broker.publish('orders', 'one');
      await broker.publish('orders', 'two');

      expect(ids, [1, 2]);
    });

    test('disposes the scope when the message ends', () async {
      final di = DIImpl()
        ..registerRequestScoped(() => Session(++Session.built));
      final scoped = ConsumerRegistry(
        broker: broker,
        di: DIHandler(di)..finishRegistration(),
      );

      await scoped.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => RequestScopedDI.current.get<Session>(),
      );

      await broker.publish('orders', 'one');

      // A consumer that never released its per-message resources would leak
      // one per message, which is worse than a request leak: nothing here is
      // bounded by a client giving up.
      expect(Session.disposed, [1]);
    });
  });

  group('draining', () {
    test('finishes a message already in hand', () async {
      final release = Completer<void>();
      var finished = false;

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) async {
          await release.future;
          finished = true;
        },
      );

      unawaited(broker.publish('orders', 'slow'));
      await Future<void>.delayed(Duration.zero);

      final drained = registry.drain(const Duration(seconds: 5));
      release.complete();

      expect(await drained, isTrue);
      expect(finished, isTrue);
    });

    test('stops taking new messages', () async {
      final seen = <String>[];

      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );

      await registry.drain(const Duration(seconds: 1));
      await broker.publish('orders', 'after');

      // Cancelling instead would abandon in-flight work; pausing stops new
      // work while letting what is in hand finish.
      expect(seen, isEmpty);
      expect(registry.isDraining, isTrue);
    });

    test('reports failure when a handler outlasts the timeout', () async {
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => Completer<void>().future,
      );

      unawaited(broker.publish('orders', 'stuck'));
      await Future<void>.delayed(Duration.zero);

      expect(
        await registry.drain(const Duration(milliseconds: 100)),
        isFalse,
      );
    });

    test('drains immediately with nothing in hand', () async {
      expect(await registry.drain(const Duration(seconds: 1)), isTrue);
    });

    test('a failed handler does not stall the drain', () async {
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) => throw StateError('boom'),
      );

      unawaited(broker.publish('orders', 'bad').catchError((Object _) {}));
      await Future<void>.delayed(Duration.zero);

      expect(await registry.drain(const Duration(seconds: 2)), isTrue);
    });
  });

  group('close', () {
    test('releases subscriptions and the broker', () async {
      await registry.consume(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );

      expect(registry.subscriptions, 1);

      await registry.close();

      expect(registry.subscriptions, 0);
      expect(
        () => broker.publish('orders', 'after'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
