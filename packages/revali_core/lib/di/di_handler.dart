import 'package:revali_core/di/di.dart';
import 'package:revali_core/di/request_scoped_registry.dart';

class DIHandler implements DI, RequestScopedRegistry {
  DIHandler(DI di) : _di = di;

  final DI _di;

  bool _canRegister = true;
  void finishRegistration() {
    _canRegister = false;
  }

  void _ensureOpen() {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }
  }

  @override
  T get<T extends Object>() => _di.get<T>();

  /// Forwarded so the per-request container can find request-scoped
  /// registrations through this wrapper.
  @override
  T Function()? requestScopedFactory<T extends Object>() {
    if (_di case final RequestScopedRegistry registry) {
      return registry.requestScopedFactory<T>();
    }

    return null;
  }

  @override
  void registerSingleton<T extends Object>(T instance) {
    _ensureOpen();

    _di.registerSingleton<T>(instance);
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _ensureOpen();

    _di.registerFactory<T>(factory);
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _ensureOpen();

    _di.registerLazySingleton<T>(factory);
  }

  @override
  void registerRequestScoped<T extends Object>(T Function() factory) {
    _ensureOpen();

    _di.registerRequestScoped<T>(factory);
  }
}
