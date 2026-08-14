import 'dart:async';

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
