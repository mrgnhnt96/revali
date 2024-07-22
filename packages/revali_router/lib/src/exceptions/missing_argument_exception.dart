class MissingArgumentException implements Exception {
  const MissingArgumentException({
    required this.key,
    required this.location,
  });

  final String key;
  final String location;

  @override
  String toString() {
    return 'MissingArgumentException: key: $key, location: $location';
  }
}
