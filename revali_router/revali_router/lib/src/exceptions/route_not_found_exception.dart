class RouteNotFoundException implements Exception {
  const RouteNotFoundException({
    required this.method,
    required this.path,
  });

  final String path;
  final String method;

  @override
  String toString() => 'RouteNotFoundException: $method $path';
}
