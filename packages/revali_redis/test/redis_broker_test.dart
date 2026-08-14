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
}
