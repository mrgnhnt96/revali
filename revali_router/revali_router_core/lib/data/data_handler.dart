import 'package:revali_router_core/data/read_only_data_handler.dart';
import 'package:revali_router_core/data/write_only_data_handler.dart';

class DataHandler implements WriteOnlyDataHandler, ReadOnlyDataHandler {
  DataHandler();

  final _registered = <Type, dynamic>{};

  /// Register an instance of [T] to be used later.
  @override
  void add<T>(T instance) {
    _registered[T] = instance;
  }

  @override
  T? get<T>() {
    final result = _registered[T];

    if (result == null) {
      return null;
    }

    return result as T;
  }

  @override
  bool has<T>() {
    return _registered.containsKey(T);
  }

  @override
  bool contains<T>(T value) {
    return _registered.containsValue(value);
  }

  @override
  bool remove<T>() {
    if (has<T>()) {
      _registered.remove(T);

      return true;
    }

    return false;
  }
}
