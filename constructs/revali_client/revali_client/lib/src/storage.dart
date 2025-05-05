abstract interface class Storage {
  const Storage();

  Future<Object?> operator [](String key);
  Future<void> save(String key, Object? value);
  Future<void> saveAll(Map<String, Object?> values);
  Future<void> clear();
}
