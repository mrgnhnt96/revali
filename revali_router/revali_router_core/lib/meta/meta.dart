class Meta {
  Meta();

  final _registered = <Type, List<dynamic>>{};

  /// Adds an instance to meta, which can be retrieved later.
  ///
  /// The key for the instance is the type of the instance.
  void add<T>(T instance) {
    (_registered[T] ??= []).add(instance);
  }

  List<T>? get<T>() {
    final result = _registered[T];

    return List<T>.from(result! as List<T>, growable: false);
  }

  bool has<T>() {
    return _registered.containsKey(T);
  }
}
