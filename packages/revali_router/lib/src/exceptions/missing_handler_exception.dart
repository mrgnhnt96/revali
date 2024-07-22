class MissingHandlerException implements Exception {
  const MissingHandlerException({
    required this.method,
    required this.path,
  });

  final String method;
  final String path;

  @override
  String toString() => 'MissingHandlerException: $method $path';
}
