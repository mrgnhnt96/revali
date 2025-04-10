import 'package:revali_core/di/di.dart';

class DIHandler implements DI {
  DIHandler(DI di) : _di = di;

  final DI _di;

  bool _canRegister = true;
  void finishRegistration() {
    _canRegister = false;
  }

  @override
  T get<T extends Object>() => _di.get<T>();

  @override
  @Deprecated('Use registerFactory instead')
  void register<T extends Object>(Factory<T> factory) =>
      registerFactory<T>(factory);

  @override
  @Deprecated('Use registerSingleton instead')
  void registerInstance<T extends Object>(T instance) =>
      registerSingleton(instance);

  @override
  void registerSingleton<T extends Object>(T instance) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _di.registerSingleton<T>(instance);
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _di.registerFactory<T>(factory);
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _di.registerLazySingleton<T>(factory);
  }
}
