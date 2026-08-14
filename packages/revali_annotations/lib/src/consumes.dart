/// Marks a method as the handler for messages on [topic].
///
/// ```dart
/// @Controller('orders')
/// class OrdersController {
///   const OrdersController();
///
///   @Consumes('order.placed', group: 'billing')
///   Future<void> onPlaced(BrokerMessage message) async { ... }
/// }
/// ```
///
/// The handler runs with the same per-message treatment a request gets: its
/// own dependency scope and a `TraceContext` seeded from the message headers,
/// and it takes part in shutdown. It does **not** run guards or middleware —
/// a guard exists to reject a caller, and a message has none.
///
/// Nothing is registered unless the app supplies a broker from
/// `AppConfig.createBroker()`.
final class Consumes {
  const Consumes(this.topic, {required this.group});

  /// The topic or queue to receive from.
  final String topic;

  /// The consumer group this handler belongs to.
  ///
  /// Members of one group share the work — each message goes to exactly one
  /// of them. Two *different* groups on the same topic each get their own
  /// copy, which is how several services react to one event without the
  /// publisher knowing about any of them.
  ///
  /// Required rather than defaulted: the default would have to be derived
  /// from something (the package name, the class), and a group name that
  /// changes when code is renamed silently re-reads a stream from scratch.
  final String group;
}
