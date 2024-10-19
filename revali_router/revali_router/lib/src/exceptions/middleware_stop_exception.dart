class MiddlewareStopException implements Exception {
  const MiddlewareStopException(this.name);

  final String name;

  @override
  String toString() => 'MiddlewareStopException: $name';
}
