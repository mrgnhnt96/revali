import 'dart:async';

import 'package:revali_core/di/di.dart';
import 'package:revali_core/di/di_impl.dart';

/// A per-request [DI] container, typically installed via a zone in a
/// request wrapper lifecycle component.
class RequestScopedDI implements DI {
  RequestScopedDI({required DI parent}) : _parent = parent;

  static const zoneKey = #requestScopedDI;

  final DI _parent;
  final DIImpl _local = DIImpl();

  static RequestScopedDI? get maybeCurrent {
    final value = Zone.current[zoneKey];
    if (value is RequestScopedDI) {
      return value;
    }

    return null;
  }

  static RequestScopedDI get current {
    final value = maybeCurrent;
    if (value == null) {
      throw StateError(
        'No RequestScopedDI in the current zone. '
        'Register a RequestWrapper that installs RequestScopedDI.zoneKey.',
      );
    }

    return value;
  }

  static T getFrom<T extends Object>(DI fallback) {
    return maybeCurrent?.get<T>() ?? fallback.get<T>();
  }

  Future<void> onError(Object error, StackTrace stackTrace) async {}

  Future<void> dispose() async {}

  @override
  T get<T extends Object>() {
    try {
      return _local.get<T>();
    } catch (_) {
      return _parent.get<T>();
    }
  }

  @override
  @Deprecated('Use registerSingleton instead')
  void registerInstance<T extends Object>(T instance) =>
      registerSingleton<T>(instance);

  @override
  void registerSingleton<T extends Object>(T instance) {
    _local.registerSingleton<T>(instance);
  }

  @override
  @Deprecated('Use registerFactory or registerLazySingleton instead')
  void register<T extends Object>(Factory<T> factory) =>
      registerFactory<T>(factory);

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _local.registerFactory<T>(factory);
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _local.registerLazySingleton<T>(factory);
  }
}
