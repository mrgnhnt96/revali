import 'dart:async';
import 'dart:convert';

import 'package:revali_core/revali_core.dart';
import 'package:revali_redis/src/redis_connection.dart';
import 'package:revali_redis/src/resp.dart';

/// A [MessageBroker] backed by Redis Streams.
///
/// Streams rather than pub/sub: Redis pub/sub is fire-and-forget, so a
/// consumer that is restarting simply misses whatever was published, which is
/// the opposite of what a work queue is for. Streams persist, and consumer
/// groups give exactly the semantics the contract describes — one delivery per
/// group, redelivery until acknowledged.
///
/// Delivery is **at least once**. A handler that succeeds but whose `XACK` is
/// lost will see its message again, so handlers must be idempotent.
class RedisBroker implements MessageBroker {
  RedisBroker({
    required RedisConnection connection,
    required RedisConnection Function() openConnection,
    this.consumerName = 'revali',
    this.blockFor = const Duration(seconds: 2),
    this.batchSize = 16,
    this.claimAfter,
    this.maxDeliveries = 5,
    this.deadLetterSuffix = '.dead',
  }) : _control = connection,
       _openConnection = openConnection;

  /// Connects to a Redis server.
  ///
  /// Each subscription gets its own connection, because `XREADGROUP` blocks:
  /// sharing one would stall every publish behind a consumer waiting for work.
  static Future<RedisBroker> connect({
    String host = 'localhost',
    int port = 6379,
    String consumerName = 'revali',
  }) async {
    final connections = <SocketRedisConnection>[];

    // Opened eagerly so a bad host or port fails here rather than on the first
    // publish, but held behind a reconnecting wrapper: a server restart kills
    // the control connection exactly as it kills the consumers', and a
    // publish must not throw forever afterwards.
    final first = await SocketRedisConnection.connect(host, port);
    connections.add(first);

    final control = ReconnectingRedisConnection(() async {
      final opened = await SocketRedisConnection.connect(host, port);
      connections.add(opened);

      return opened;
    }, initial: first);

    return RedisBroker(
      connection: control,
      consumerName: consumerName,
      openConnection: () {
        // Opened lazily and awaited by the caller; see
        // [ReconnectingRedisConnection].
        final connection = ReconnectingRedisConnection(() async {
          final opened = await SocketRedisConnection.connect(host, port);
          connections.add(opened);

          return opened;
        });

        return connection;
      },
    );
  }

  final RedisConnection _control;
  final RedisConnection Function() _openConnection;

  /// Identifies this process within a consumer group.
  ///
  /// Redis tracks unacknowledged messages per consumer name, so two replicas
  /// sharing one name makes each other's pending entries invisible.
  final String consumerName;

  /// How long `XREADGROUP` waits for work before returning empty.
  ///
  /// Bounded rather than infinite so a shutdown never waits longer than this
  /// for the read loop to notice it should stop.
  final Duration blockFor;

  final int batchSize;

  /// How long an entry may sit unacknowledged before another consumer takes
  /// it over.
  ///
  /// Redis tracks pending entries **per consumer name**, so a replica that
  /// dies mid-message leaves its entries in a list nobody else reads. Without
  /// this they are stranded until something restarts under the same name —
  /// which never happens when a pod is replaced rather than restarted.
  ///
  /// Null disables reclaiming, which is the previous behaviour. Set it well
  /// above the time a healthy handler takes, or a slow handler's work gets
  /// taken from underneath it and processed twice.
  final Duration? claimAfter;

  /// How many deliveries an entry gets before it is dead-lettered.
  ///
  /// Reclaiming without this turns a message that always fails into a retry
  /// storm: claimed, failed, left pending, claimed again, forever. Past this
  /// count the entry is published to the dead-letter topic and acknowledged,
  /// so the queue moves on and the message is still somewhere a human can
  /// look at it.
  final int maxDeliveries;

  /// Appended to the topic name to form the dead-letter topic.
  final String deadLetterSuffix;

  final _subscriptions = <_RedisSubscription>[];
  var _closed = false;

  @override
  Future<void> publish(
    String topic,
    String payload, {
    Map<String, String> headers = const {},
  }) async {
    if (_closed) {
      throw StateError('Broker is closed');
    }

    await _control.send([
      'XADD',
      topic,
      '*',
      'payload',
      payload,
      'headers',
      jsonEncode(headers),
    ]);
  }

  @override
  Future<BrokerSubscription> subscribe(
    String topic, {
    required String group,
    required MessageHandler onMessage,
  }) async {
    if (_closed) {
      throw StateError('Broker is closed');
    }

    await _ensureGroup(topic, group);

    final subscription = _RedisSubscription(
      topic: topic,
      group: group,
      consumerName: consumerName,
      connection: _openConnection(),
      onMessage: onMessage,
      blockFor: blockFor,
      batchSize: batchSize,
      claimAfter: claimAfter,
      maxDeliveries: maxDeliveries,
      deadLetterTopic: '$topic$deadLetterSuffix',
      ensureGroup: () => _ensureGroup(topic, group, from: '0'),
    );

    _subscriptions.add(subscription);
    subscription.start();

    return subscription;
  }

  /// Creates the consumer group, tolerating one that already exists.
  ///
  /// `MKSTREAM` so a consumer may start before anything has ever been
  /// published — otherwise the first deploy order between two services
  /// decides whether either of them works.
  ///
  /// [from] is where a NEW group starts reading. `\$` — only what arrives
  /// next — is right on first subscribe: a consumer joining an existing
  /// stream should not replay its whole history.
  ///
  /// It is wrong when RE-creating a group a server restart destroyed. The
  /// stream is gone too, so recovery races the next publish: if a message
  /// lands before the group is back, `\$` starts *after* it and that message
  /// is never delivered to anyone. Nothing reports it — the publish succeeded
  /// and the consumer is healthy. Recreating from `0` reads the rebuilt
  /// stream from its start, which is only ever what arrived after the
  /// restart, since the restart is what emptied it.
  Future<void> _ensureGroup(
    String topic,
    String group, {
    String from = r'$',
  }) async {
    try {
      await _control.send(['XGROUP', 'CREATE', topic, group, from, 'MKSTREAM']);
    } on RedisError catch (e) {
      if (!e.isBusyGroup) {
        rethrow;
      }
    }
  }

  @override
  Future<void> close() async {
    _closed = true;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _control.close();
  }
}

class _RedisSubscription implements BrokerSubscription {
  _RedisSubscription({
    required this.topic,
    required this.group,
    required this.consumerName,
    required RedisConnection connection,
    required MessageHandler onMessage,
    required this.blockFor,
    required this.batchSize,
    required this.claimAfter,
    required this.maxDeliveries,
    required this.deadLetterTopic,
    required Future<void> Function() ensureGroup,
  }) : _connection = connection,
       _onMessage = onMessage,
       _ensureGroup = ensureGroup;

  @override
  final String topic;

  final String group;
  final String consumerName;
  final RedisConnection _connection;
  final MessageHandler _onMessage;

  /// Recreates the consumer group after a server restart loses it.
  final Future<void> Function() _ensureGroup;
  final Duration blockFor;
  final int batchSize;
  final Duration? claimAfter;
  final int maxDeliveries;
  final String deadLetterTopic;

  var _paused = false;
  var _cancelled = false;
  Future<void>? _loop;

  void start() => _loop = _read();

  Future<void> _read() async {
    while (!_cancelled) {
      if (_paused) {
        // Paused, not stopped: the loop stays alive so a resumed subscription
        // does not need re-establishing.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        continue;
      }

      final Object? reply;
      try {
        reply = await _connection.send([
          'XREADGROUP',
          'GROUP',
          group,
          consumerName,
          'BLOCK',
          '${blockFor.inMilliseconds}',
          'COUNT',
          '$batchSize',
          'STREAMS',
          topic,
          '>',
        ]);
      } on RedisError catch (e) {
        if (_cancelled) {
          return;
        }

        if (!e.isNoGroup) {
          rethrow;
        }

        // The server came back without our group -- a restart with no
        // persistence is the ordinary cause. The connection is healthy, so
        // nothing else here would ever notice: every read from now on fails
        // this same way, and the consumer is silently dead while looking
        // fine. Recreate it and carry on.
        try {
          await _ensureGroup();
        } catch (_) {
          // Racing another replica doing the same thing is expected; the next
          // read finds the group either way.
        }

        // Backed off deliberately. If recreating the group does not stick --
        // the server is still coming up, or another replica is racing -- the
        // next read fails NOGROUP again, and without a pause this becomes a
        // tight XGROUP CREATE loop against a server that is already
        // struggling. It also keeps the loop yielding to timers rather than
        // spinning on microtasks alone.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        continue;
      } catch (_) {
        if (_cancelled) {
          return;
        }

        // A dropped connection must not end the loop silently; back off and
        // let the next attempt surface it.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final messages = parseStreamReply(reply, topic);

      for (final message in messages) {
        if (_cancelled) {
          return;
        }

        await _handle(message);
      }

      // Only when there was no fresh work: reclaiming is a repair path, and
      // running it while messages are flowing would spend round trips on
      // bookkeeping instead of the queue.
      if (messages.isEmpty) {
        await _reclaim();
      }
    }
  }

  /// Runs the handler and acknowledges only on success.
  ///
  /// A handler that threw leaves the entry pending, which is what makes
  /// redelivery possible at all.
  Future<void> _handle(BrokerMessage message) async {
    try {
      await _onMessage(message);
      await _connection.send(['XACK', topic, group, message.id]);
    } catch (_) {
      // Left unacknowledged deliberately.
    }
  }

  /// Takes over entries another consumer left pending, and dead-letters the
  /// ones that have failed too often.
  Future<void> _reclaim() async {
    final idle = claimAfter;
    if (idle == null || _cancelled) {
      return;
    }

    final List<PendingEntry> pending;
    try {
      pending = parsePendingReply(
        await _connection.send([
          'XPENDING',
          topic,
          group,
          'IDLE',
          '${idle.inMilliseconds}',
          '-',
          '+',
          '$batchSize',
        ]),
      );
    } catch (_) {
      return;
    }

    if (pending.isEmpty) {
      return;
    }

    final claimable = <String>[];

    for (final entry in pending) {
      if (entry.deliveries > maxDeliveries) {
        await _deadLetter(entry);
      } else {
        claimable.add(entry.id);
      }
    }

    if (claimable.isEmpty || _cancelled) {
      return;
    }

    try {
      final claimed = await _connection.send([
        'XCLAIM',
        topic,
        group,
        consumerName,
        '${idle.inMilliseconds}',
        ...claimable,
      ]);

      for (final message in parseEntries(claimed, topic)) {
        if (_cancelled) {
          return;
        }

        await _handle(message);
      }
    } catch (_) {
      // The entries stay pending; the next pass tries again.
    }
  }

  /// Moves an entry that has failed too often onto the dead-letter topic.
  ///
  /// Acknowledged afterwards so the queue moves on. Acknowledging *first*
  /// would risk losing it entirely if the copy failed.
  Future<void> _deadLetter(PendingEntry entry) async {
    try {
      final claimed = parseEntries(
        await _connection.send([
          'XCLAIM',
          topic,
          group,
          consumerName,
          '0',
          entry.id,
        ]),
        topic,
      );

      for (final message in claimed) {
        await _connection.send([
          'XADD',
          deadLetterTopic,
          '*',
          'payload',
          message.payload,
          'headers',
          jsonEncode({
            ...message.headers,
            'x-dead-letter-reason': 'delivered ${entry.deliveries} times',
            'x-dead-letter-topic': topic,
          }),
        ]);
      }

      await _connection.send(['XACK', topic, group, entry.id]);
    } catch (_) {
      // Left pending rather than dropped.
    }
  }

  @override
  Future<void> pause() async => _paused = true;

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _paused = true;

    await _loop;
    await _connection.close();
  }
}

/// Turns an `XREADGROUP` reply into messages.
///
/// The reply nests three levels deep — streams, then entries, then a flat
/// field/value list — and is null when the block expired with no work.
List<BrokerMessage> parseStreamReply(Object? reply, String topic) {
  if (reply is! List) {
    return const [];
  }

  final messages = <BrokerMessage>[];

  for (final stream in reply) {
    if (stream is! List || stream.length < 2) {
      continue;
    }

    final entries = stream[1];
    if (entries is! List) {
      continue;
    }

    messages.addAll(parseEntries(entries, topic));
  }

  return messages;
}

/// Turns a flat list of stream entries into messages.
///
/// `XCLAIM` replies with this shape directly, while `XREADGROUP` nests it one
/// level deeper under each stream.
List<BrokerMessage> parseEntries(Object? entries, String topic) {
  if (entries is! List) {
    return const [];
  }

  final messages = <BrokerMessage>[];

  for (final entry in entries) {
    if (entry is! List || entry.length < 2) {
      continue;
    }

    final id = entry[0];
    final fields = entry[1];
    if (id is! String || fields is! List) {
      continue;
    }

    final values = <String, String>{};
    for (var i = 0; i + 1 < fields.length; i += 2) {
      final key = fields[i];
      final value = fields[i + 1];
      if (key is String && value is String) {
        values[key] = value;
      }
    }

    messages.add(
      BrokerMessage(
        topic: topic,
        id: id,
        payload: values['payload'] ?? '',
        headers: _decodeHeaders(values['headers']),
      ),
    );
  }

  return messages;
}

/// One entry from an `XPENDING` reply.
class PendingEntry {
  const PendingEntry({required this.id, required this.deliveries});

  final String id;

  /// How many times Redis has handed this entry to a consumer.
  ///
  /// The guard against a poison message: an entry that keeps failing has its
  /// count climb, and past a threshold it is dead-lettered rather than
  /// reclaimed forever.
  final int deliveries;
}

/// Parses the extended `XPENDING` reply: `[id, consumer, idle, deliveries]`.
List<PendingEntry> parsePendingReply(Object? reply) {
  if (reply is! List) {
    return const [];
  }

  final entries = <PendingEntry>[];

  for (final entry in reply) {
    if (entry is! List || entry.length < 4) {
      continue;
    }

    final id = entry[0];
    final deliveries = entry[3];

    if (id is! String) {
      continue;
    }

    entries.add(
      PendingEntry(
        id: id,
        // Redis replies with an integer, but a string would still be a count.
        deliveries: deliveries is int
            ? deliveries
            : int.tryParse('$deliveries') ?? 1,
      ),
    );
  }

  return entries;
}

Map<String, String> _decodeHeaders(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const {};
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const {};
    }

    return {
      for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
    };
  } catch (_) {
    // Headers are metadata; a malformed set must not cost the message.
    return const {};
  }
}

/// A connection opened on first use.
///
/// `subscribe` needs a connection synchronously but opening a socket is
/// asynchronous, so the first command waits for the connect rather than the
/// caller doing so.
