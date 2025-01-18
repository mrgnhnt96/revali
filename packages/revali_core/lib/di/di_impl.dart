import 'package:revali_core/revali_core.dart';

class DIImpl implements DI {
  DIImpl()
      : _singletons = {},
        _lazySingletons = {};

  final Map<Type, dynamic> _singletons;
  final Map<Type, dynamic> _lazySingletons;

  @override
  void registerInstance<T extends Object>(T instance) {
    _register<T>(_singletons, instance);
  }

  @override
  void register<T extends Object>(Factory<T> factory) {
    _register<T>(_lazySingletons, factory);
  }

  void _register<T>(Map<Type, dynamic> map, dynamic value) {
    _ensureUnique<T>();
    map[T] = value;
  }

  void _ensureUnique<T>() {
    if (_singletons.containsKey(T) || _lazySingletons.containsKey(T)) {
      throw Exception('Type $T already registered');
    }
  }

  @override
  T get<T extends Object>() {
    if (_singletons[T] case final T value?) {
      return value;
    }

    if (_lazySingletons[T] case final T Function() factory?) {
      return _singletons[T] = factory();
    }

    throw Exception(
      'Nothing found for type $T within $DI, did you forget to register it?',
    );
  }
}
