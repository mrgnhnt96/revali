import 'dart:async';

import 'package:revali_core/di/di.dart';
import 'package:revali_core/di/request_scoped_di.dart';
import 'package:revali_core/messaging/broker_message.dart';
import 'package:revali_core/messaging/message_broker.dart';
import 'package:revali_core/trace/trace_context.dart';

/// Registers consumers and gives each message the same treatment a request
/// gets.
///
/// A hand-rolled consumer sits outside everything the framework provides: no
/// per-message dependency scope, no correlation, and no part in shutdown — so
/// a deploy drains HTTP properly while the consumer keeps pulling work and is
/// killed mid-message. This closes all three.
class ConsumerRegistry {
  ConsumerRegistry({required this.broker, this.di});

  final MessageBroker broker;

  /// The application container each message scopes from, when there is one.
  final DI? di;

  final _subscriptions = <BrokerSubscription>[];
  final _inFlight = <Future<void>>{};

  var _draining = false;

  /// Whether a shutdown has begun. Readiness-style checks can consult it.
  bool get isDraining => _draining;

  /// Messages currently being handled.
  int get inFlight => _inFlight.length;

  int get subscriptions => _subscriptions.length;

  /// Subscribes [onMessage] to [topic].
  ///
  /// Each message runs with its own [TraceContext] — seeded from the message
  /// headers, so an event published during a request stays on that request's
  /// trace even when it is handled minutes later in another process — and its
  /// own [RequestScopedDI] when a container was supplied.
  Future<void> consume(
    String topic, {
    required String group,
    required MessageHandler onMessage,
  }) async {
    final subscription = await broker.subscribe(
      topic,
      group: group,
      onMessage: (message) => _handle(message, onMessage),
    );

    _subscriptions.add(subscription);
  }

  Future<void> _handle(BrokerMessage message, MessageHandler onMessage) {
    final work = _run(message, onMessage);

    // Tracked so a drain can wait for it. Errors are the handler's business —
    // they must not make the drain give up on the messages still in hand.
    final tracked = work.catchError((Object _) {});
    _inFlight.add(tracked);
    unawaited(tracked.whenComplete(() => _inFlight.remove(tracked)));

    return work;
  }

  Future<void> _run(BrokerMessage message, MessageHandler onMessage) async {
    final trace = TraceContext.from(
      requestId: message.headers[TraceContext.requestIdHeader],
      traceparent: message.headers[TraceContext.traceparentHeader],
      tracestate: message.headers[TraceContext.tracestateHeader],
      baggage: TraceContext.decodeBaggage(
        message.headers[TraceContext.baggageHeader],
      ),
    );

    if (di case final parent?) {
      final scope = RequestScopedDI(parent: parent);

      try {
        await scope.run(() => trace.runWith(() async => onMessage(message)));
      } finally {
        await scope.dispose();
      }

      return;
    }

    await trace.runWith(() async => onMessage(message));
  }

  /// Stops taking new messages and waits for those in hand, up to [timeout].
  ///
  /// Returns true when everything finished. Pausing before waiting is the
  /// whole point: cancelling outright would abandon messages mid-handler and,
  /// on an at-least-once broker, hand every one of them to another consumer
  /// as a duplicate.
  Future<bool> drain(Duration timeout) async {
    _draining = true;

    for (final subscription in _subscriptions) {
      try {
        await subscription.pause();
      } catch (_) {
        // A broker that cannot pause still gets cancelled below.
      }
    }

    if (_inFlight.isNotEmpty) {
      try {
        await Future.wait(_inFlight.toList()).timeout(timeout);
      } on TimeoutException {
        return false;
      }
    }

    return true;
  }

  /// Cancels every subscription and closes the broker.
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();

    await broker.close();
  }
}
