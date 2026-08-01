/// One recorded request for the debug / inspect ring buffer.
class RequestTrace {
  const RequestTrace({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.durationMs,
    required this.at,
    this.error,
  });

  final String method;
  final String path;
  final int statusCode;
  final int durationMs;
  final String? error;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'method': method,
        'path': path,
        'statusCode': statusCode,
        'durationMs': durationMs,
        if (error != null) 'error': error,
        'at': at.toIso8601String(),
      };
}
