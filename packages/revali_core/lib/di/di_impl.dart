import 'package:revali_core/revali_core.dart';

class DIImpl implements DI {
  DIImpl()
      : _factories = {},
        _singletons = {},
        _lazySingletons = {};

  final Map<Type, dynamic> _factories;
  final Map<Type, dynamic> _singletons;
  final Map<Type, dynamic> _lazySingletons;

  @override
  @Deprecated('Use registerSingleton instead')
  void registerInstance<T extends Object>(T instance) =>
      registerSingleton<T>(instance);

  @override
  void registerSingleton<T extends Object>(T instance) {
    _register<T>(_singletons, instance);
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _register<T>(_factories, factory);
  }

  @Deprecated('Use registerFactory or registerLazySingleton instead')
  @override
  void register<T extends Object>(Factory<T> factory) =>
      registerFactory<T>(factory);

  void _register<T>(Map<Type, dynamic> map, dynamic value) {
    _ensureUnique<T>();
    map[T] = value;
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _register<T>(_lazySingletons, factory);
  }

  void _ensureUnique<T>() {
    if (_singletons.containsKey(T) ||
        _lazySingletons.containsKey(T) ||
        _factories.containsKey(T)) {
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

    if (_factories[T] case final T Function() factory?) {
      return factory();
    }

    throw Exception(
      'Nothing found for type $T within $DI, did you forget to register it?',
    );
  }
}
