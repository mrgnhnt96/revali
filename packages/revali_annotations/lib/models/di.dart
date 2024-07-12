typedef Factory<T> = T Function();

class _Entry<T> {
  _Entry(this.value, {required this.onDispose});

  final dynamic value;
  void Function(T)? onDispose;
}

class DI {
  DI()
      : _singletons = {},
        _lazySingletons = {},
        _factories = {};

  final Map<Type, _Entry> _singletons;
  final Map<Type, _Entry> _lazySingletons;
  final Map<Type, _Entry> _factories;
  bool _canRegister = true;

  void registerSingleton<T>(T instance, {void Function(T)? onDispose}) =>
      _register<T>(_singletons, _Entry<T>(instance, onDispose: onDispose));

  void registerLazySingleton<T>(Factory<T> factory,
          {void Function(T)? onDispose}) =>
      _register<T>(_lazySingletons, _Entry<T>(factory, onDispose: onDispose));

  void registerFactory<T>(Factory<T> factory) =>
      _register<T>(_factories, _Entry<T>(factory, onDispose: null));

  void _register<T>(Map<Type, dynamic> map, _Entry value) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _ensureUnique<T>();
    map[T] = value;
  }

  void _ensureUnique<T>() {
    if (_singletons.containsKey(T) ||
        _lazySingletons.containsKey(T) ||
        _factories.containsKey(T)) {
      throw Exception('Type $T already registered');
    }
  }

  void finishRegistration() {
    _canRegister = false;
  }

  T get<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T]!.value;
    }

    if (_lazySingletons.containsKey(T)) {
      final entry = _lazySingletons[T]!;
      final value = entry.value();
      _singletons[T] = _Entry(value, onDispose: entry.onDispose);
      return value;
    }

    final entry = _factories[T];
    final result = entry?.value();

    if (result == null) {
      throw Exception('No factory found for type $T');
    }

    return result;
  }

  T call<T>() => get<T>();

  void dispose() {
    for (final entry in _singletons.values) {
      entry.onDispose?.call(entry.value);
    }
  }
}
