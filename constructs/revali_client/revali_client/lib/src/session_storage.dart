import 'package:revali_client/src/storage.dart';

class SessionStorage implements Storage {
  SessionStorage() : _storage = {};

  final Map<String, Object?> _storage;

  @override
  Future<Object?> operator [](String key) async {
    return _storage[key];
  }

  @override
  Future<void> save(String key, Object? value) async {
    switch (value) {
      case null:
        _storage.remove(key);
      default:
        _storage[key] = value;
    }
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    _storage.addAll(values);
  }
}
