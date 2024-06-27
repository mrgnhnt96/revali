typedef Factory<T> = T Function();

class DI {
  factory DI() => instance;
  static final DI instance = DI._();
  DI._();

  Map<Type, dynamic> _singletons = {};
  Map<Type, Factory<dynamic>> _lazySingletons = {};
  Map<Type, Factory<dynamic>> _factories = {};

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  void registerLazySingleton<T>(Factory<T> factory) {
    _lazySingletons[T] = factory;
  }

  void registerFactory<T>(Factory<T> factory) {
    _factories[T] = factory;
  }

  T get<T>() {
    final result = (_singletons[T] ??= _lazySingletons[T]?.call()) ??
        _factories[T]?.call();

    if (result == null) {
      throw Exception('No factory found for type $T');
    }

    return result;
  }

  T call<T>() => get<T>();
}
