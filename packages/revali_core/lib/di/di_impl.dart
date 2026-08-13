import 'package:revali_core/di/di.dart';
import 'package:revali_core/di/request_scoped_registry.dart';

class DIImpl implements DI, RequestScopedRegistry {
  DIImpl()
      : _factories = {},
        _singletons = {},
        _lazySingletons = {},
        _requestScoped = {};

  final Map<Type, dynamic> _factories;
  final Map<Type, dynamic> _singletons;
  final Map<Type, dynamic> _lazySingletons;
  final Map<Type, dynamic> _requestScoped;

  @override
  void registerSingleton<T extends Object>(T instance) {
    _register<T>(_singletons, instance);
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _register<T>(_factories, factory);
  }

  @override
  void registerRequestScoped<T extends Object>(T Function() factory) {
    _register<T>(_requestScoped, factory);
  }

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
        _factories.containsKey(T) ||
        _requestScoped.containsKey(T)) {
      throw Exception('Type $T already registered');
    }
  }

  /// The request-scoped factory for [T], or null if [T] is not request
  /// scoped. Used by the per-request container to build its own instance.
  @override
  T Function()? requestScopedFactory<T extends Object>() {
    if (_requestScoped[T] case final T Function() factory?) {
      return factory;
    }

    return null;
  }

  /// Whether [T] was registered with [registerRequestScoped].
  bool isRequestScoped<T extends Object>() => _requestScoped.containsKey(T);

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

    // Reached only outside a request — the per-request container resolves
    // these itself. Building one here would hand back an instance nothing
    // ever disposes and that no other caller in the request would share,
    // which is exactly the bug request scoping exists to prevent.
    if (_requestScoped.containsKey(T)) {
      throw StateError(
        '$T is registered as request scoped and cannot be resolved outside '
        'a request. It is available in handlers, middleware, guards, '
        'interceptors and exception catchers.',
      );
    }

    throw Exception(
      'Nothing found for type $T within $DI, did you forget to register it?',
    );
  }
}
