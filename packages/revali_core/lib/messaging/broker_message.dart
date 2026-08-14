import 'dart:convert';

/// One message, as a consumer sees it.
class BrokerMessage {
  const BrokerMessage({
    required this.topic,
    required this.id,
    required this.payload,
    this.headers = const {},
  });

  /// The topic or queue it arrived on.
  final String topic;

  /// The broker's identifier for this delivery.
  ///
  /// Used to acknowledge it. Not a business key: a broker may deliver the same
  /// logical event twice with different ids, which is why handlers have to be
  /// idempotent regardless of what this says.
  final String id;

  final String payload;

  /// Metadata carried alongside the body.
  ///
  /// Correlation headers ride here, so a message published during a request
  /// stays on that request's trace when it is handled — possibly minutes
  /// later, in another process.
  final Map<String, String> headers;

  /// The payload decoded as JSON.
  ///
  /// Throws on a payload that is not JSON; use [payload] when the producer
  /// sends something else.
  Object? get json => jsonDecode(payload);

  @override
  String toString() => 'BrokerMessage($topic/$id)';
}
