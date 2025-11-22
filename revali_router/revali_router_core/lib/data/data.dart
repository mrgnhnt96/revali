abstract class Data {
  const factory Data() = _DataAnnotation;

  /// Register an instance of [T] to be used later.
  void add<T>(T instance);

  /// Get the data of a specific type.
  ///
  /// ```dart
  /// {String, 'Hello, World!'}
  ///
  /// data.get<String>(); // 'Hello, World!'
  /// data.get<User>(); // null
  /// ```
  T? get<T>();

  /// Check if the data contains a specific type.
  ///
  /// ```dart
  /// {String, 'Hello, World!'}
  ///
  /// data.has<String>(); // true
  /// ```
  bool has<T>();

  /// Check if the data contains a specific value.
  ///
  /// ```dart
  /// {String, 'Hello, World!'}
  ///
  /// data.contains<String>('Hello, World!'); // true
  /// ```
  bool contains<T>(T value);

  /// Remove the data of a specific type.
  ///
  /// ```dart
  /// {String, 'Hello, World!'}
  ///
  /// data.remove<String>(); // true
  /// data.remove<User>(); // false
  /// ```
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
