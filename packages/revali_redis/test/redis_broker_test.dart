import 'dart:async';
import 'dart:convert';

import 'package:revali_core/revali_core.dart';
import 'package:revali_redis/revali_redis.dart';
import 'package:test/test.dart';

/// Stands in for a Redis server: records commands and replays scripted
/// XREADGROUP results.
class FakeConnection implements RedisConnection {
  FakeConnection({this.batches = const []});

  /// One reply per XREADGROUP call; exhausted batches reply empty, which is
  /// what a real server does when its block expires.
  final List<Object?> batches;

  final commands = <List<String>>[];
  int _reads = 0;
  bool closed = false;

  /// Set to fail the next XGROUP CREATE.
  RedisError? groupError;

  /// Reply for XPENDING: `[id, consumer, idle, deliveries]` per entry.
  ///
  /// Acknowledged ids are filtered out, the way Redis stops reporting an
  /// entry once it leaves the pending list. A fake that kept replaying them
  /// would make a single dead-letter look like an infinite loop.
  Object? pendingReply;

  final _acked = <String>{};

  /// Reply for XCLAIM, in stream-entry shape.
  Object? claimReply;

  List<List<String>> of(String name) =>
      commands.where((c) => c.first == name).toList();

  @override
  Future<Object?> send(List<String> command) async {
    commands.add(command);

    switch (command.first) {
      case 'XGROUP':
        if (groupError case final error?) {
          throw error;
        }

        return 'OK';
      case 'XACK':
        _acked.add(command.last);

        return 1;
      case 'XPENDING':
        if (pendingReply case final List<Object?> entries) {
          return [
            for (final entry in entries)
              if (entry is List && !_acked.contains(entry.first)) entry,
          ];
        }

        return pendingReply ?? <Object?>[];
      case 'XCLAIM':
        return claimReply ?? <Object?>[];
      case 'XREADGROUP':
        if (_reads < batches.length) {
          return batches[_reads++];
        }

        _reads++;
        // Give the read loop somewhere to yield rather than spinning hot.
        await Future<void>.delayed(const Duration(milliseconds: 5));

        return null;
      default:
        return 'OK';
    }
  }

  @override
  Future<void> close() async => closed = true;
}

/// One XREADGROUP reply carrying [entries] on [topic].
Object streamReply(String topic, List<(String, Map<String, String>)> entries) {
  return [
    [
      topic,
      [
        for (final (id, fields) in entries)
          [
            id,
            [
              for (final e in fields.entries) ...[e.key, e.value],
            ],
          ],
      ],
    ],
  ];
}

RedisBroker brokerWith(FakeConnection connection) => RedisBroker(
  connection: connection,
  openConnection: () => connection,
  blockFor: const Duration(milliseconds: 5),
);

void main() {
  group('publish', () {
    test('appends to the stream with payload and headers', () async {
      final connection = FakeConnection();

      await brokerWith(
        connection,
      ).publish('orders', 'placed', headers: {'X-Request-Id': 'abc'});

      final command = connection.of('XADD').single;

      expect(command.take(3), ['XADD', 'orders', '*']);
      expect(command[command.indexOf('payload') + 1], 'placed');
      expect(jsonDecode(command[command.indexOf('headers') + 1]), {
        'X-Request-Id': 'abc',
      });
    });

    test('refuses to publish once closed', () async {
      final broker = brokerWith(FakeConnection());
      await broker.close();

      expect(
        () => broker.publish('orders', 'placed'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('subscribe', () {
    test('creates the consumer group with MKSTREAM', () async {
      final connection = FakeConnection();
      final broker = brokerWith(connection);

      final subscription = await broker.subscribe(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );
      await subscription.cancel();

      // MKSTREAM so a consumer may start before anything was ever published;
      // otherwise deploy order decides whether the service works.
      expect(connection.of('XGROUP').single, [
        'XGROUP',
        'CREATE',
        'orders',
        'billing',
        r'$',
        'MKSTREAM',
      ]);
    });

    test('tolerates a group that already exists', () async {
      final connection = FakeConnection()
        ..groupError = const RedisError('BUSYGROUP already exists');
      final broker = brokerWith(connection);

      // Every restart after the first hits this; treating it as fatal would
      // make the second deploy fail.
      final subscription = await broker.subscribe(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );
      await subscription.cancel();
    });

    test('rethrows a group error that is not BUSYGROUP', () async {
      final connection = FakeConnection()
        ..groupError = const RedisError('ERR wrong type');

      expect(
        () => brokerWith(
          connection,
        ).subscribe('orders', group: 'billing', onMessage: (_) {}),
        throwsA(isA<RedisError>()),
      );
    });
  });

  group('consuming', () {
    test('delivers an entry to the handler', () async {
      final connection = FakeConnection(
        batches: [
          streamReply('orders', [
            ('1-0', {'payload': 'placed', 'headers': '{}'}),
          ]),
        ],
      );

      final seen = <BrokerMessage>[];
      final subscription = await brokerWith(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: seen.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(seen.single.payload, 'placed');
      expect(seen.single.id, '1-0');
      expect(seen.single.topic, 'orders');
    });

    test('acknowledges a handled entry', () async {
      final connection = FakeConnection(
        batches: [
          streamReply('orders', [
            ('1-0', {'payload': 'placed', 'headers': '{}'}),
          ]),
        ],
      );

      final subscription = await brokerWith(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(connection.of('XACK').single, [
        'XACK',
        'orders',
        'billing',
        '1-0',
      ]);
    });

    test('does not acknowledge when the handler throws', () async {
      final connection = FakeConnection(
        batches: [
          streamReply('orders', [
            ('1-0', {'payload': 'placed', 'headers': '{}'}),
          ]),
        ],
      );

      final subscription = await brokerWith(connection).subscribe(
        'orders',
        group: 'billing',
        onMessage: (_) => throw StateError('boom'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Leaving it pending is what makes redelivery possible; acking a failed
      // handler would silently drop the message.
      expect(connection.of('XACK'), isEmpty);
    });

    test('carries headers through to the message', () async {
      final connection = FakeConnection(
        batches: [
          streamReply('orders', [
            (
              '1-0',
              {
                'payload': 'placed',
                'headers': '{"X-Request-Id":"abc","baggage":"t=1"}',
              },
            ),
          ]),
        ],
      );

      BrokerMessage? seen;
      final subscription = await brokerWith(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (m) => seen = m);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(seen?.headers, {'X-Request-Id': 'abc', 'baggage': 't=1'});
    });

    test('survives malformed headers rather than losing the message', () async {
      final connection = FakeConnection(
        batches: [
          streamReply('orders', [
            ('1-0', {'payload': 'placed', 'headers': 'not json'}),
          ]),
        ],
      );

      BrokerMessage? seen;
      final subscription = await brokerWith(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (m) => seen = m);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Headers are metadata; a malformed set must not cost the payload.
      expect(seen?.payload, 'placed');
      expect(seen?.headers, isEmpty);
    });

    test('names itself as the consumer within the group', () async {
      final connection = FakeConnection();
      final broker = RedisBroker(
        connection: connection,
        openConnection: () => connection,
        consumerName: 'replica-2',
        blockFor: const Duration(milliseconds: 5),
      );

      final subscription = await broker.subscribe(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      // Redis tracks pending entries per consumer name, so two replicas
      // sharing one make each other's pending work invisible.
      final read = connection.of('XREADGROUP').first;
      expect(read[read.indexOf('GROUP') + 2], 'replica-2');
    });
  });

  group('parseStreamReply', () {
    test('returns nothing for the empty-block reply', () {
      // XREADGROUP replies null when its block expires with no work.
      expect(parseStreamReply(null, 'orders'), isEmpty);
    });

    test('returns nothing for an unexpected shape', () {
      expect(parseStreamReply('surprise', 'orders'), isEmpty);
      expect(parseStreamReply([1, 2, 3], 'orders'), isEmpty);
    });

    test('reads several entries in one batch', () {
      final messages = parseStreamReply(
        streamReply('orders', [
          ('1-0', {'payload': 'one', 'headers': '{}'}),
          ('2-0', {'payload': 'two', 'headers': '{}'}),
        ]),
        'orders',
      );

      expect(messages.map((m) => m.payload), ['one', 'two']);
      expect(messages.map((m) => m.id), ['1-0', '2-0']);
    });

    test('defaults a missing payload to empty rather than throwing', () {
      final messages = parseStreamReply(
        streamReply('orders', [
          ('1-0', {'headers': '{}'}),
        ]),
        'orders',
      );

      expect(messages.single.payload, '');
    });
  });

  group('close', () {
    test('closes the control connection', () async {
      final connection = FakeConnection();

      await brokerWith(connection).close();

      expect(connection.closed, isTrue);
    });
  });

  group('reclaiming', () {
    Object pending(String id, int deliveries) => [
      [id, 'dead-replica', 60000, deliveries],
    ];

    Object claimed(String id, String payload) => [
      [
        id,
        ['payload', payload, 'headers', '{}'],
      ],
    ];

    RedisBroker reclaimingBroker(
      FakeConnection connection, {
      int maxDeliveries = 5,
    }) => RedisBroker(
      connection: connection,
      openConnection: () => connection,
      blockFor: const Duration(milliseconds: 5),
      claimAfter: const Duration(seconds: 30),
      maxDeliveries: maxDeliveries,
    );

    test('is off by default', () async {
      final connection = FakeConnection()..pendingReply = pending('1-0', 1);

      final subscription = await brokerWith(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Reclaiming changes when a message is redelivered, so it stays opt-in.
      expect(connection.of('XPENDING'), isEmpty);
    });

    test('takes over an entry another consumer left pending', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 1)
        ..claimReply = claimed('1-0', 'stranded');

      final seen = <String>[];
      final subscription = await reclaimingBroker(connection).subscribe(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // Redis tracks pending entries per consumer name, so without this a
      // replica that died mid-message strands them where nobody looks.
      expect(seen, contains('stranded'));
      expect(connection.of('XCLAIM'), isNotEmpty);
    });

    test('acknowledges a reclaimed entry it handled', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 1)
        ..claimReply = claimed('1-0', 'stranded');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      expect(connection.of('XACK').map((c) => c.last), contains('1-0'));
    });

    test('only asks for entries idle beyond claimAfter', () async {
      final connection = FakeConnection()..pendingReply = <Object?>[];

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      final command = connection.of('XPENDING').first;

      expect(command[command.indexOf('IDLE') + 1], '30000');
    });

    test('dead-letters an entry that has failed too often', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 9)
        ..claimReply = claimed('1-0', 'poison');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // Without this, a message that always fails is claimed, failed and
      // claimed again forever -- reclaiming turns a stuck message into a
      // retry storm.
      final dead = connection
          .of('XADD')
          .where((c) => c[1] == 'orders.dead')
          .toList();

      expect(dead, hasLength(1));
      expect(dead.single[dead.single.indexOf('payload') + 1], 'poison');
    });

    test('records why a message was dead-lettered', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 9)
        ..claimReply = claimed('1-0', 'poison');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      final dead = connection
          .of('XADD')
          .firstWhere((c) => c[1] == 'orders.dead');
      final headers =
          jsonDecode(dead[dead.indexOf('headers') + 1]) as Map<String, dynamic>;

      // A dead letter nobody can explain is nearly as bad as a lost one.
      expect(headers['x-dead-letter-reason'], contains('9'));
      expect(headers['x-dead-letter-topic'], 'orders');
    });

    test('acknowledges a dead-lettered entry so the queue moves on', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 9)
        ..claimReply = claimed('1-0', 'poison');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      expect(connection.of('XACK').map((c) => c.last), contains('1-0'));
    });

    test('does not dead-letter an entry still within its allowance', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 5)
        ..claimReply = claimed('1-0', 'retryable');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // Exactly at the limit is still allowed; past it is not.
      expect(
        connection.of('XADD').where((c) => c[1] == 'orders.dead'),
        isEmpty,
      );
    });
  });

  group('parsePendingReply', () {
    test('reads id and delivery count', () {
      final entries = parsePendingReply([
        ['1-0', 'consumer', 1000, 3],
      ]);

      expect(entries.single.id, '1-0');
      expect(entries.single.deliveries, 3);
    });

    test('ignores a malformed entry rather than throwing', () {
      expect(parsePendingReply([1, 'nope', <Object?>[]]), isEmpty);
    });

    test('returns nothing when there is nothing pending', () {
      expect(parsePendingReply(null), isEmpty);
      expect(parsePendingReply(<Object?>[]), isEmpty);
    });
  });
}
