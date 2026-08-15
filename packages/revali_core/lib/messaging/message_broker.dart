import 'dart:async';

import 'package:revali_core/isolate/isolate_identity.dart';
import 'package:revali_core/messaging/broker_message.dart';

/// What a handler does with a message.
typedef MessageHandler = FutureOr<void> Function(BrokerMessage message);

/// A live subscription to a topic.
abstract interface class BrokerSubscription {
  String get topic;

  /// Stops pulling **new** messages without cancelling.
  ///
  /// This is the first move of a graceful shutdown: stop taking work, then
  /// finish what is already in hand. Cancelling outright would abandon
  /// messages mid-handler, which for an at-least-once broker means they are
  /// redelivered — correct, but a duplicate nobody needed.
  Future<void> pause();

  /// Stops pulling and releases the subscription.
  Future<void> cancel();
}

/// A message broker this service publishes to and consumes from.
///
/// Revali does **not** run a broker. Like a database, the broker is
/// infrastructure you deploy; this is the client side of it. Implementations
/// live in their own packages so the framework never has to pick a winner
/// between brokers whose delivery and ordering guarantees genuinely differ.
///
/// Handlers must be **idempotent**. Every broker worth using delivers at least
/// once, which means a message that was handled but whose acknowledgement was
/// lost will arrive again. That is not a bug to be engineered away at this
/// layer — it is the contract.
///
/// ## Implementing one
///
/// If the broker identifies this client to the server **by name** — a Redis
/// Streams consumer, a Kafka `group.instance.id`, a NATS durable — run that
/// name through [IsolateIdentity.scopeName] before sending it. `createBroker`
/// runs in every isolate of an app with `AppConfig.workers` above 1, so a name
/// passed through untouched makes every worker claim to be the same client.
/// On a broker that tracks unacknowledged work per client that is not a
/// cosmetic collision: each worker's pending messages become invisible to the
/// others, and the app looks healthy while work sits unretried.
///
/// The framework cannot do this for you. It never sees the name — the
/// implementation builds it — so this is an obligation of the implementation,
/// and the reason [IsolateIdentity.scopeName] is public.
abstract interface class MessageBroker {
  /// Sends [payload] to [topic].
  ///
  /// [headers] carry metadata rather than data — correlation identifiers,
  /// typically. Anything a consumer needs in order to do its job belongs in
  /// the payload.
  Future<void> publish(
    String topic,
    String payload, {
    Map<String, String> headers = const {},
  });

  /// Receives messages from [topic], calling [onMessage] for each.
  ///
  /// [group] names a set of consumers that share the work: every message goes
  /// to exactly one member. Two *different* groups on the same topic each get
  /// their own copy, which is how several services react to one event without
  /// the publisher knowing about any of them.
  ///
  /// A handler that throws does not acknowledge, leaving the message for
  /// redelivery.
  Future<BrokerSubscription> subscribe(
    String topic, {
    required String group,
    required MessageHandler onMessage,
  });

  Future<void> close();
}
