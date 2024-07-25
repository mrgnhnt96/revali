class CloseWebSocketException implements Exception {
  const CloseWebSocketException([this.code = 1000, this.reason = '']);

  final int code;
  final String reason;

  @override
  String toString() {
    return 'CloseWebSocketException: code: $code, reason: $reason';
  }
}
