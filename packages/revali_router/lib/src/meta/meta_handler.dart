typedef Factory<T> = T Function();

class MetaHandler {
  MetaHandler();

  Map<Type, List<dynamic>> _registered = {};

  void register<T>(T instance) {
    (_registered[T] ??= []).add(instance);
  }

  List<T>? get<T>() {
    final result = _registered[T];

    return List<T>.from(result as List<T>, growable: false);
  }

  bool has<T>() {
    return _registered.containsKey(T);
  }
}
