import 'dart:async';
import 'dart:math';

/// Correlation identifiers for one request, ambient for its whole lifetime.
///
/// A request id that only exists as a header dies at the first hop: a call the
/// handler makes to another service opens a fresh, uncorrelated request, and
/// the two services' logs cannot be joined afterwards. This carries the
/// identifiers in the zone instead, so anything running inside the request —
/// a logger, a repository, an outbound client — can reach them without being
/// handed them explicitly.
///
/// ```dart
/// final id = TraceContext.current?.requestId;
/// ```
///
/// Sending them on is [outboundHeaders]. Nothing does that automatically:
/// what counts as a trusted peer is the app's call, not the framework's, and
/// forwarding correlation headers to an arbitrary third party is a small
/// information leak.
///
/// This deliberately **propagates** `traceparent` rather than creating spans.
/// A collector that already understands W3C Trace Context keeps working, and
/// a service that sits between two instrumented ones stops breaking the
/// chain — without this package taking on span lifecycles, samplers or
/// exporters.
class TraceContext {
  TraceContext({
    required this.requestId,
    this.traceparent,
    this.tracestate,
    Map<String, String>? baggage,
  }) : baggage = baggage ?? {};

  /// Builds a context from whatever the caller sent, generating what is
  /// missing.
  ///
  /// A blank or absent request id becomes a fresh one, so every request has an
  /// id whether or not the caller supplied one. `traceparent` is carried
  /// verbatim when present and **not** invented when absent — a malformed or
  /// fabricated one is worse than none, because a collector will happily
  /// stitch it into the wrong trace.
  factory TraceContext.from({
    String? requestId,
    String? traceparent,
    String? tracestate,
    Map<String, String>? baggage,
  }) {
    return TraceContext(
      requestId: switch (requestId) {
        final String id when id.trim().isNotEmpty => id,
        _ => newRequestId(),
      },
      traceparent: _orNull(traceparent),
      tracestate: _orNull(tracestate),
      baggage: baggage,
    );
  }

  /// Identifies this request across every service that handles it.
  final String requestId;

  /// W3C Trace Context `traceparent`, when the caller sent one.
  final String? traceparent;

  /// W3C Trace Context `tracestate`, when the caller sent one.
  final String? tracestate;

  /// Key/value pairs to carry alongside the identifiers — a tenant, a
  /// feature-flag cohort.
  ///
  /// Mutable, so a component early in the request can add to it and an
  /// outbound call later in the same request picks it up. It **crosses the
  /// wire** in [outboundHeaders], so treat it as public to every service you
  /// call: no credentials, no personal data.
  final Map<String, String> baggage;

  static const requestIdHeader = 'X-Request-Id';
  static const traceparentHeader = 'traceparent';
  static const tracestateHeader = 'tracestate';
  static const baggageHeader = 'baggage';

  static const zoneKey = #revaliTraceContext;

  /// The context for the request currently being handled, if any.
  ///
  /// Null outside a request — a background timer, a startup hook, or a
  /// `Router` used without going through [runWith].
  static TraceContext? get current {
    final value = Zone.current[zoneKey];

    return value is TraceContext ? value : null;
  }

  /// Runs [body] with this context installed as the ambient one.
  R runWith<R>(R Function() body) =>
      runZoned(body, zoneValues: {zoneKey: this});

  /// The headers to attach to an outbound call so the next service joins this
  /// request rather than starting its own.
  Map<String, String> outboundHeaders() {
    return {
      requestIdHeader: requestId,
      if (traceparent case final value?) traceparentHeader: value,
      if (tracestate case final value?) tracestateHeader: value,
      if (encodedBaggage() case final value?) baggageHeader: value,
    };
  }

  /// [baggage] in the W3C `baggage` header format, or null when empty.
  ///
  /// Keys and values are percent-encoded: an unescaped `,` or `=` would be
  /// read by the next service as a delimiter and silently split one entry
  /// into two.
  String? encodedBaggage() {
    if (baggage.isEmpty) {
      return null;
    }

    return baggage.entries
        .map(
          (e) => '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        )
        .join(',');
  }

  /// Parses a W3C `baggage` header value.
  ///
  /// Entries that are not `key=value` are skipped rather than throwing — this
  /// runs on input from another service, and one malformed entry must not
  /// fail the request.
  static Map<String, String> decodeBaggage(String? header) {
    if (header == null || header.trim().isEmpty) {
      return {};
    }

    final result = <String, String>{};

    for (final entry in header.split(',')) {
      final index = entry.indexOf('=');
      if (index <= 0) {
        continue;
      }

      final key = Uri.decodeQueryComponent(entry.substring(0, index).trim());
      final value = Uri.decodeQueryComponent(entry.substring(index + 1).trim());

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  /// A fresh request id: 16 random bytes, hex encoded.
  static String newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String? _orNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }
}
