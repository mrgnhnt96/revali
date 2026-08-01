class MissingArgumentException implements Exception {
  const MissingArgumentException({
    required this.key,
    required this.location,
    this.expectedType,
    this.actualType,
    this.message,
  });

  final String key;
  final String location;

  /// Declared parameter type (e.g. `String`, `Set<String>`).
  final String? expectedType;

  /// Runtime type of the bound value, or `null` when absent.
  final String? actualType;

  /// Optional human-readable detail.
  final String? message;

  @override
  String toString() {
    final buffer = StringBuffer(
      'MissingArgumentException: key: $key, location: $location',
    );
    if (expectedType != null) {
      buffer.write(', expected: $expectedType');
    }
    if (actualType != null) {
      buffer.write(', actual: $actualType');
    }
    if (message != null && message!.isNotEmpty) {
      buffer.write(', message: $message');
    }
    return buffer.toString();
  }
}
