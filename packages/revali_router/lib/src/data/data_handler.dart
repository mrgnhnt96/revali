class DataHandler {
  DataHandler();

  Map<Type, dynamic> _registered = {};

  /// Register an instance of [T] to be used later.
  void add<T>(T instance) {
    _registered[T] = instance;
  }

  T? get<T>() {
    final result = _registered[T];

    if (result == null) {
      return null;
    }

    return result as T;
  }

  bool has<T>() {
    return _registered.containsKey(T);
  }
}
