import 'dart:convert';

/// A non-2xx response from the server.
///
/// When the peer sent a structured error envelope —
/// `{"error": {"code": ..., "message": ...}}`, which `HttpError` produces —
/// [code], [reason] and [details] carry it. When it did not, they are null and
/// only [statusCode] and [body] are available, so a plain-text or third-party
/// peer behaves exactly as before.
///
/// ```dart
/// try {
///   await client.users.get(id: 1);
/// } on ServerException catch (e) {
///   if (e.code == 'user_not_found') { ... }
/// }
/// ```
class ServerException implements Exception {
  const ServerException({
    required this.message,
    required this.statusCode,
    this.body,
    this.code,
    this.reason,
    this.details,
  });

  /// Builds from a raw response body, reading the error envelope when present.
  ///
  /// Parsing is best-effort by design: this runs on whatever another service
  /// sent, and a malformed or unexpected body must surface as the HTTP failure
  /// it already is rather than as a `FormatException` from the client.
  factory ServerException.fromBody({
    required String message,
    required int statusCode,
    String? body,
  }) {
    if (body == null || body.isEmpty) {
      return ServerException(message: message, statusCode: statusCode);
    }

    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return ServerException(
        message: message,
        statusCode: statusCode,
        body: body,
      );
    }

    if (decoded is! Map || decoded['error'] is! Map) {
      return ServerException(
        message: message,
        statusCode: statusCode,
        body: body,
      );
    }

    final error = decoded['error'] as Map;
    final code = error['code'];
    final reason = error['message'];
    final details = error['details'];

    return ServerException(
      message: message,
      statusCode: statusCode,
      body: body,
      code: code is String ? code : null,
      reason: reason is String ? reason : null,
      details: details is Map ? Map<String, dynamic>.from(details) : null,
    );
  }

  /// The HTTP reason phrase.
  final String message;

  final int statusCode;

  /// The raw body, always available.
  final String? body;

  /// The peer's stable error identifier, when it sent one.
  ///
  /// This is the part worth branching on. Null for a peer that does not send
  /// the envelope.
  final String? code;

  /// The peer's human-readable explanation, when it sent one.
  ///
  /// Never parse this — it is free to change wording, which is why [code]
  /// exists.
  final String? reason;

  /// Extra machine-readable context the peer attached.
  final Map<String, dynamic>? details;

  /// Whether the peer sent a structured error envelope.
  bool get isStructured => code != null;

  @override
  String toString() {
    return [
      '[$statusCode] ServerException: $message',
      if (code != null) 'Code: $code',
      if (reason != null) 'Reason: $reason',
      if (details != null) 'Details: $details',
      if (body != null) 'Body: $body',
    ].join('\n');
  }
}
