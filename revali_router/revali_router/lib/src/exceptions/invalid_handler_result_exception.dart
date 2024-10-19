class InvalidHandlerResultException implements Exception {
  const InvalidHandlerResultException(
    this.type,
    this.expected,
  );

  final String type;
  final List<String> expected;

  @override
  String toString() {
    return 'InvalidHandlerResultException: $type, expected: $expected';
  }
}
