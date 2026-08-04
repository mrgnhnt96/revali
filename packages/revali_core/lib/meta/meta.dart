class Meta {
  Meta();

  final _registered = <Type, List<dynamic>>{};

  /// Adds an instance to meta, which can be retrieved later.
  ///
  /// The key for the instance is the type of the instance.
  void add<T>(T instance) {
    (_registered[T] ??= <T>[]).add(instance);
  }

  List<T>? get<T>() {
    if (_registered[T] case final result?) {
      return List<T>.from(result, growable: false);
    }

    return null;
  }

  bool has<T>() {
    return _registered.containsKey(T);
  }
}
