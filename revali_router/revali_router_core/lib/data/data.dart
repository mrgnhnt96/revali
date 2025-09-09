abstract class Data {
  const factory Data() = _DataAnnotation;

  /// Register an instance of [T] to be used later.
  void add<T>(T instance);

  T? get<T>();

  bool has<T>();

  bool contains<T>(T value);

  bool remove<T>();
}

class _DataAnnotation implements Data {
  const _DataAnnotation();

  @override
  void add<T>(T instance) {
    throw StateError('Not intended for runtime usage');
  }

  @override
  bool contains<T>(T value) {
    throw StateError('Not intended for runtime usage');
  }

  @override
  T? get<T>() {
    throw StateError('Not intended for runtime usage');
  }

  @override
  bool has<T>() {
    throw StateError('Not intended for runtime usage');
  }

  @override
  bool remove<T>() {
    throw StateError('Not intended for runtime usage');
  }
}
