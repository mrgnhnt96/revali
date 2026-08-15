import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// Replayed for every XREADGROUP once [batches] runs out.
  ///
  /// Keeps the read loop permanently busy, which is the only way to observe
  /// what the loop does when it never sees an idle pass.
  Object? repeatingBatch;

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

        return repeatingBatch;
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

  group('consumer name per isolate', () {
    // Restored rather than left set: `current` is process-wide, so a fake
    // identity that outlives its test renames the consumer of every test that
    // runs after it, and the failure looks like it came from somewhere else.
    tearDown(
      () => IsolateIdentity.setCurrentForGeneratedCode(IsolateIdentity.single),
    );

    test('leaves the parent isolate untouched', () {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 0, workerCount: 4),
      );

      // The upgrade-safety guard. Suffixing the parent too would rename the
      // consumer of every app that upgrades, stranding whatever is pending
      // under the old name.
      final broker = RedisBroker(
        connection: FakeConnection(),
        openConnection: FakeConnection.new,
        consumerName: 'orders',
      );

      expect(broker.consumerName, 'orders');
    });

    test('suffixes a worker isolate with its index', () {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 2, workerCount: 4),
      );

      final broker = RedisBroker(
        connection: FakeConnection(),
        openConnection: FakeConnection.new,
        consumerName: 'orders',
      );

      expect(broker.consumerName, 'orders-2');
    });

    test('suffixes the default name too', () {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 1, workerCount: 2),
      );

      final broker = RedisBroker(
        connection: FakeConnection(),
        openConnection: FakeConnection.new,
      );

      expect(broker.consumerName, 'revali-1');
    });

    test('sends the suffixed name to Redis, not just reports it', () async {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 3, workerCount: 4),
      );

      final connection = FakeConnection();
      final broker = RedisBroker(
        connection: connection,
        openConnection: () => connection,
        consumerName: 'orders',
        blockFor: const Duration(milliseconds: 5),
        claimAfter: const Duration(seconds: 30),
      );

      final subscription = await broker.subscribe(
        'orders',
        group: 'billing',
        onMessage: (_) {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await subscription.cancel();

      // A getter that agrees with itself proves nothing: what matters is the
      // name in the commands, since that is the one Redis keys pending
      // entries on.
      final read = connection.of('XREADGROUP').first;
      expect(read[read.indexOf('GROUP') + 2], 'orders-3');

      // And on the paths that scope work to *this* consumer, which are the
      // ones the collision actually strands.
      expect(connection.of('XPENDING').first.last, 'orders-3');
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

      // Reclaiming changes when ANOTHER consumer's message is redelivered, so
      // it stays opt-in. The IDLE form is the reclaim scan; the consumer-scoped
      // form is this consumer retrying its own failures, which is always on.
      expect(
        connection.of('XPENDING').where((c) => c.contains('IDLE')),
        isEmpty,
      );
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

      final command = connection
          .of('XPENDING')
          .firstWhere((c) => c.contains('IDLE'));

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
        ..pendingReply = pending('1-0', 4)
        ..claimReply = claimed('1-0', 'retryable');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // Four deliveries of an allowance of five leaves one, so this is a
      // retry rather than a dead letter.
      expect(
        connection.of('XADD').where((c) => c[1] == 'orders.dead'),
        isEmpty,
      );
    });

    test('dead-letters on the delivery that reaches maxDeliveries', () async {
      final connection = FakeConnection()
        ..pendingReply = pending('1-0', 5)
        ..claimReply = claimed('1-0', 'spent');

      final subscription = await reclaimingBroker(
        connection,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // `maxDeliveries: 5` means five deliveries, not five and then one more.
      // Redis has already made all five here, so there is no allowance left
      // to spend and retrying would be the sixth.
      expect(
        connection.of('XADD').where((c) => c[1] == 'orders.dead'),
        hasLength(1),
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

    test('reads the idle time the backoff is measured against', () {
      final entries = parsePendingReply([
        ['1-0', 'consumer', 12000, 3],
      ]);

      expect(entries.single.idle, const Duration(seconds: 12));
    });

    test('reads an idle time replied as a string', () {
      final entries = parsePendingReply([
        ['1-0', 'consumer', '12000', 3],
      ]);

      expect(entries.single.idle, const Duration(seconds: 12));
    });

    test('treats an unreadable idle time as due now', () {
      final entries = parsePendingReply([
        ['1-0', 'consumer', null, 3],
      ]);

      // Zero means "retry it" -- the alternative is an entry that no backoff
      // ever releases, which is the stall this whole path exists to end.
      expect(entries.single.idle, Duration.zero);
    });

    test('ignores a malformed entry rather than throwing', () {
      expect(parsePendingReply([1, 'nope', <Object?>[]]), isEmpty);
    });

    test('returns nothing when there is nothing pending', () {
      expect(parsePendingReply(null), isEmpty);
      expect(parsePendingReply(<Object?>[]), isEmpty);
    });
  });

  group('own pending entries', () {
    Object ownPending(String id, int deliveries, {int idleMs = 1000}) => [
      [id, 'revali', idleMs, deliveries],
    ];

    Object ownClaimed(String id, String payload) => [
      [
        id,
        ['payload', payload, 'headers', '{}'],
      ],
    ];

    /// A broker that retries the moment it notices, which is what these tests
    /// about *whether* redelivery happens want. The backoff is the subject of
    /// its own group, and leaving it on here would only mean sleeping.
    RedisBroker eagerBroker(
      FakeConnection connection, {
      int maxDeliveries = 5,
    }) => RedisBroker(
      connection: connection,
      openConnection: () => connection,
      blockFor: const Duration(milliseconds: 5),
      retryAfter: Duration.zero,
      maxDeliveries: maxDeliveries,
    );

    // `XREADGROUP ... >` returns only messages never delivered to anyone, so a
    // handler that threw left its entry pending and nothing read it again.
    // Reclaiming was the only path that touched pending entries and it is off
    // unless claimAfter is set -- so on a DEFAULT broker a failed message was
    // never redelivered, never dead-lettered and never reported. It stopped,
    // silently, which is worse than failing loudly.

    test('a failed message is retried without claimAfter being set', () async {
      final connection = FakeConnection()
        ..pendingReply = ownPending('1-1', 1)
        ..claimReply = ownClaimed('1-1', 'placed');

      final seen = <String>[];
      final broker = eagerBroker(connection);
      final subscription = await broker.subscribe(
        'orders',
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      // No claimAfter anywhere in this test: redelivery must not depend on it.
      expect(seen, contains('placed'));
      expect(
        connection.of('XPENDING').first,
        contains('revali'),
        reason:
            'the pending scan must be scoped to this consumer -- entries '
            'belonging to others are for reclaim, which waits claimAfter',
      );
    });

    test(
      'redelivery uses XCLAIM, so the delivery count actually climbs',
      () async {
        final connection = FakeConnection()
          ..pendingReply = [
            ['1-1', 'revali', 1000, 1],
          ]
          ..claimReply = [
            ['1-1', 'payload', 'placed', 'headers', '{}'],
          ];

        final broker = eagerBroker(connection);
        final subscription = await broker.subscribe(
          'orders',
          group: 'billing',
          onMessage: (_) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await subscription.cancel();

        // Reading own pending with `0` would NOT increment Redis's delivery
        // counter, so maxDeliveries would never be reached and a poison message
        // would retry forever -- the exact failure this path exists to end.
        final claims = connection.of('XCLAIM');
        expect(claims, isNotEmpty);
        expect(
          claims.first,
          containsAllInOrder(<String>['XCLAIM', 'orders', 'billing', 'revali']),
        );
      },
    );

    test(
      'a message past maxDeliveries is dead-lettered, not retried forever',
      () async {
        final connection = FakeConnection()
          ..pendingReply = ownPending('1-1', 9)
          ..claimReply = ownClaimed('1-1', 'poison');

        final broker = RedisBroker(
          connection: connection,
          openConnection: () => connection,
          blockFor: const Duration(milliseconds: 5),
          maxDeliveries: 3,
        );

        final seen = <String>[];
        final subscription = await broker.subscribe(
          'orders',
          group: 'billing',
          onMessage: (m) => seen.add(m.payload),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await subscription.cancel();

        // Dead-lettering no longer depends on claimAfter either.
        final dead = connection
            .of('XADD')
            .where((c) => c.contains('orders.dead'))
            .toList();
        expect(dead, isNotEmpty, reason: 'should have been dead-lettered');
        expect(connection.of('XACK').map((c) => c.last), contains('1-1'));
      },
    );
  });

  group('retry backoff', () {
    // Redelivery used to run at the speed of the read loop: fail, notice,
    // claim, fail again. A handler whose dependency is thirty seconds into a
    // restart spent its entire maxDeliveries allowance inside that window and
    // dead-lettered a message that would have succeeded on the next attempt.
    // The wait is what makes a retry a second chance rather than a second
    // reading of the same instant.

    Object pendingAt(String id, int deliveries, int idleMs) => [
      [id, 'revali', idleMs, deliveries],
    ];

    Object claimedEntry(String id) => [
      [
        id,
        ['payload', 'placed', 'headers', '{}'],
      ],
    ];

    RedisBroker backoffBroker(
      FakeConnection connection, {
      Duration retryAfter = const Duration(seconds: 5),
      int maxDeliveries = 5,
    }) => RedisBroker(
      connection: connection,
      openConnection: () => connection,
      blockFor: const Duration(milliseconds: 5),
      retryAfter: retryAfter,
      maxDeliveries: maxDeliveries,
    );

    Future<FakeConnection> run(
      Object pending, {
      Duration retryAfter = const Duration(seconds: 5),
      int maxDeliveries = 5,
    }) async {
      final connection = FakeConnection()
        ..pendingReply = pending
        ..claimReply = claimedEntry('1-1');

      final subscription = await backoffBroker(
        connection,
        retryAfter: retryAfter,
        maxDeliveries: maxDeliveries,
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await subscription.cancel();

      return connection;
    }

    test('leaves an entry alone until retryAfter has passed', () async {
      final connection = await run(pendingAt('1-1', 1, 1000));

      expect(
        connection.of('XCLAIM'),
        isEmpty,
        reason: 'one second idle against a five second backoff is not due',
      );
    });

    test('retries an entry idle longer than retryAfter', () async {
      final connection = await run(pendingAt('1-1', 1, 6000));

      expect(connection.of('XCLAIM'), isNotEmpty);
    });

    test('doubles the wait with each delivery already made', () async {
      // Three deliveries in, the wait is 4x — twenty seconds, not five.
      final tooSoon = await run(pendingAt('1-1', 3, 15000));
      expect(tooSoon.of('XCLAIM'), isEmpty);

      final due = await run(pendingAt('1-1', 3, 25000));
      expect(due.of('XCLAIM'), isNotEmpty);
    });

    test('caps the wait at 32x', () async {
      // Without a ceiling this entry's wait would be 2^19 seconds — six days,
      // which is indistinguishable from the message being lost.
      final connection = await run(
        pendingAt('1-1', 20, 32000),
        retryAfter: const Duration(seconds: 1),
        maxDeliveries: 50,
      );

      expect(connection.of('XCLAIM'), isNotEmpty);
    });

    test('claims with the backoff as min-idle-time, not zero', () async {
      final connection = await run(pendingAt('1-1', 1, 6000));

      // The entry may have been redelivered between the scan and the claim.
      // Claiming on a stale reading would restart a handler that is running;
      // a real min-idle-time makes Redis refuse instead.
      final claim = connection.of('XCLAIM').first;
      expect(claim[4], '5000');
    });

    test('dead-letters without waiting out the backoff', () async {
      final connection = await run(pendingAt('1-1', 5, 0));

      // An entry with no allowance left has nothing to wait for — the wait
      // exists to give a retry a better chance, and there is no retry.
      expect(
        connection.of('XADD').where((c) => c[1] == 'orders.dead'),
        hasLength(1),
      );
    });

    test('Duration.zero retries at the speed of the read loop', () async {
      final connection = await run(
        pendingAt('1-1', 1, 0),
        retryAfter: Duration.zero,
      );

      final claim = connection.of('XCLAIM').first;
      expect(claim[4], '0');
    });
  });

  group('repairs under load', () {
    // The repair paths used to run only on a pass that read nothing. A queue
    // with work always waiting never has one, so for as long as the load
    // lasted a failed message was never retried and never dead-lettered --
    // the silent stall the retry path exists to end, back again under the one
    // condition nobody thinks to test.

    RedisBroker busyBroker(
      FakeConnection connection, {
      required Duration retryAfter,
      required Duration blockFor,
    }) => RedisBroker(
      connection: connection,
      openConnection: () => connection,
      blockFor: blockFor,
      retryAfter: retryAfter,
    );

    FakeConnection busyConnection() => FakeConnection()
      ..repeatingBatch = streamReply('orders', [
        ('9-9', {'payload': 'busy', 'headers': '{}'}),
      ])
      ..pendingReply = [
        ['1-1', 'revali', 60000, 1],
      ]
      ..claimReply = [
        [
          '1-1',
          ['payload', 'stalled', 'headers', '{}'],
        ],
      ];

    test('scans pending entries even while messages keep arriving', () async {
      final connection = busyConnection();

      final seen = <String>[];
      final subscription =
          await busyBroker(
            connection,
            retryAfter: Duration.zero,
            blockFor: const Duration(milliseconds: 5),
          ).subscribe(
            'orders',
            group: 'billing',
            onMessage: (m) => seen.add(m.payload),
          );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      await subscription.cancel();

      expect(
        seen,
        contains('busy'),
        reason: 'the queue must actually be busy for this to mean anything',
      );
      expect(
        connection.of('XPENDING'),
        isNotEmpty,
        reason: 'a busy queue must not starve the retry path',
      );
      expect(seen, contains('stalled'));
    });

    test('does not do the bookkeeping on every busy pass', () async {
      final connection = busyConnection();

      // The floor is a floor, not a schedule. Draining the queue is still the
      // priority, so repairs stay off the hot path until one is due.
      final subscription = await busyBroker(
        connection,
        retryAfter: const Duration(seconds: 30),
        blockFor: const Duration(seconds: 30),
      ).subscribe('orders', group: 'billing', onMessage: (_) {});

      await Future<void>.delayed(const Duration(milliseconds: 80));
      await subscription.cancel();

      expect(connection.of('XPENDING'), isEmpty);
    });
  });

  group('connect', () {
    // A socket that accepts and then says nothing. `connect` opens a
    // connection eagerly but sends no command until the first publish or
    // subscribe, so this is enough to exercise it without a Redis — which
    // matters, because the settings below are otherwise only reachable
    // through a test that a machine without a server would skip.
    late ServerSocket server;
    final accepted = <Socket>[];

    setUp(() async {
      server = (await ServerSocket.bind(InternetAddress.loopbackIPv4, 0))
        ..listen(accepted.add);
    });

    tearDown(() async {
      for (final socket in accepted) {
        socket.destroy();
      }
      accepted.clear();
      await server.close();
    });

    Future<RedisBroker> connect({
      String consumerName = 'revali',
      Duration? blockFor,
      int? batchSize,
      Duration? claimAfter,
      int? maxDeliveries,
      Duration? retryAfter,
      String? deadLetterSuffix,
    }) async {
      final broker = await RedisBroker.connect(
        host: server.address.host,
        port: server.port,
        consumerName: consumerName,
        blockFor: blockFor ?? const Duration(seconds: 2),
        batchSize: batchSize ?? 16,
        claimAfter: claimAfter,
        maxDeliveries: maxDeliveries ?? 5,
        retryAfter: retryAfter ?? const Duration(seconds: 5),
        deadLetterSuffix: deadLetterSuffix ?? '.dead',
      );
      addTearDown(broker.close);

      return broker;
    }

    test('forwards every setting to the broker', () async {
      final broker = await connect(
        consumerName: 'worker-3',
        blockFor: const Duration(milliseconds: 250),
        batchSize: 64,
        claimAfter: const Duration(seconds: 30),
        maxDeliveries: 9,
        retryAfter: const Duration(seconds: 45),
        deadLetterSuffix: '.parked',
      );

      expect(broker.consumerName, 'worker-3');
      expect(broker.blockFor, const Duration(milliseconds: 250));
      expect(broker.batchSize, 64);
      expect(broker.claimAfter, const Duration(seconds: 30));
      expect(broker.maxDeliveries, 9);
      expect(broker.retryAfter, const Duration(seconds: 45));
      expect(broker.deadLetterSuffix, '.parked');
    });

    test(
      'defaults match the constructor, so existing callers are unchanged',
      () async {
        // The point of the change was to widen `connect`'s signature without
        // moving anything underneath a caller that passes nothing. Compared
        // against a constructor-built broker rather than against literals, so
        // a future edit to one default fails here instead of drifting quietly.
        final reference = RedisBroker(
          connection: FakeConnection(),
          openConnection: FakeConnection.new,
        );
        final broker = await RedisBroker.connect(
          host: server.address.host,
          port: server.port,
        );
        addTearDown(broker.close);

        expect(broker.consumerName, reference.consumerName);
        expect(broker.blockFor, reference.blockFor);
        expect(broker.batchSize, reference.batchSize);
        expect(broker.claimAfter, reference.claimAfter);
        expect(broker.maxDeliveries, reference.maxDeliveries);
        expect(broker.retryAfter, reference.retryAfter);
        expect(broker.deadLetterSuffix, reference.deadLetterSuffix);
      },
    );
  });
}
