class GuardStopException implements Exception {
  const GuardStopException(this.name);

  final String name;

  @override
  String toString() => 'GuardStopException: $name';
}
