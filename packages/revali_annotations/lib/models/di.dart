typedef Factory<T> = T Function();

class _Entry<T> {
  _Entry(this.value, {required this.onDispose});

  final dynamic value;
  void Function(T)? onDispose;
}

class DI {
  DI()
      : _singletons = {},
        _lazySingletons = {};

  final Map<Type, dynamic> _singletons;
  final Map<Type, dynamic> _lazySingletons;
  bool _canRegister = true;

  void registerInstance<T>(T instance) => _register<T>(_singletons, instance);

  void register<T>(Factory<T> factory) =>
      _register<T>(_lazySingletons, factory);

  void _register<T>(Map<Type, dynamic> map, dynamic value) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _ensureUnique<T>();
    map[T] = value;
  }

  void _ensureUnique<T>() {
    if (_singletons.containsKey(T) || _lazySingletons.containsKey(T)) {
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

    throw Exception(
      'Nothing found for type $T within $DI, did you forget to register it?',
    );
  }

  T call<T>() => get<T>();

  void dispose() {
    for (final entry in _singletons.values) {
      entry.onDispose?.call(entry.value);
    }
  }
}
