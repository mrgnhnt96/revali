class SchemaRegistry {
  // null value = reserved (in-progress, for cycle detection)
  final _schemas = <String, Map<String, dynamic>?>{};
  final _warnings = <String>[];

  bool contains(String name) => _schemas.containsKey(name);

  /// Reserve a name before introspecting its fields to break circular refs.
  void reserve(String name) => _schemas.putIfAbsent(name, () => null);

  Map<String, dynamic> register(String name, Map<String, dynamic> schema) {
    _schemas[name] = schema;
    return {r'$ref': '#/components/schemas/$name'};
  }

  void addWarning(String message) => _warnings.add(message);

  List<String> get warnings => List.unmodifiable(_warnings);

  Map<String, dynamic> get schemasMap => Map.unmodifiable({
    for (final e in _schemas.entries)
      if (e.value case final schema?) e.key: schema,
  });

  bool get isEmpty => !_schemas.values.any((v) => v != null);
}
