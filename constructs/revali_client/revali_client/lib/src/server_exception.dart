class ServerException implements Exception {
  const ServerException({
    required this.message,
    required this.statusCode,
    this.body,
  });

  final String message;
  final int statusCode;
  final String? body;

  @override
  String toString() {
    return [
      '[$statusCode] ServerException: $message',
      if (body != null) 'Body: $body',
    ].join('\n');
  }
}
