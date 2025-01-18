import 'package:revali_core/di/di.dart';

class DIHandler implements DI {
  DIHandler(DI di) : _di = di;

  final DI _di;

  bool _canRegister = true;

  @override
  T get<T extends Object>() => _di.get<T>();

  @override
  void register<T extends Object>(Factory<T> factory) {
    if (!_canRegister) {
      throw Exception('Registration is closed, cannot register new types');
    }

    _di.register<T>(factory);
  }

  void finishRegistration() {
    _canRegister = false;
  }

  @override
  void registerInstance<T extends Object>(T instance) =>
      _di.registerInstance<T>(instance);
}
