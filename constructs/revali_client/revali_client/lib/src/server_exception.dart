class ServerException implements Exception {
  const ServerException({
    required this.message,
    required this.statusCode,
    this.body,
  });

  final String message;
  final int statusCode;
  final String? body;
}
