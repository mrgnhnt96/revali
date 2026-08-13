// ignore_for_file: avoid_print

import 'dart:async';

import 'package:revali_core/di/di.dart';
import 'package:revali_core/di/di_impl.dart';
import 'package:revali_core/di/disposable.dart';
import 'package:revali_core/di/request_scoped_registry.dart';

/// The [DI] container for one request.
///
/// Installed in a zone for the whole request pipeline, so middleware, guards,
/// interceptors, the handler and exception catchers all resolve against the
/// same scope. Anything registered with [DI.registerRequestScoped] is built
/// once here and shared for the rest of the request; everything else falls
/// through to the application container.
class RequestScopedDI implements DI {
  RequestScopedDI({required DI parent}) : _parent = parent;

  static const zoneKey = #requestScopedDI;

  final DI _parent;
  final DIImpl _local = DIImpl();

  /// Instances this scope built, in creation order.
  final List<Object> _created = [];

  final Map<Type, Object> _cache = {};

  var _disposed = false;

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
        'Request-scoped dependencies are only available while serving a '
        'request.',
      );
    }

    return value;
  }

  /// Resolves [T] from the current request scope, falling back to [fallback]
  /// when there is no request in progress.
  static T getFrom<T extends Object>(DI fallback) {
    return maybeCurrent?.get<T>() ?? fallback.get<T>();
  }

  /// Runs [body] with this scope installed, disposing it afterwards.
  ///
  /// Disposal runs whether [body] returns or throws — a request that failed
  /// still has to release its transaction.
  Future<R> run<R>(Future<R> Function() body) async {
    try {
      return await runZoned(body, zoneValues: {zoneKey: this});
    } finally {
      await dispose();
    }
  }

  /// Releases everything this scope created, in reverse creation order.
  ///
  /// A dependency can therefore rely on whatever it was built from still
  /// being alive while it shuts down. Errors are logged rather than thrown:
  /// the response has already been sent, and one failing teardown must not
  /// skip the rest.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    for (final instance in _created.reversed) {
      if (instance is! Disposable) {
        continue;
      }

      try {
        await instance.dispose();
      } catch (e, st) {
        print('Failed to dispose ${instance.runtimeType}: $e\n$st');
      }
    }

    _created.clear();
    _cache.clear();
  }

  @override
  T get<T extends Object>() {
    if (_cache[T] case final T cached?) {
      return cached;
    }

    // Anything registered directly on this scope wins.
    try {
      return _local.get<T>();
    } catch (_) {
      // Not registered locally; fall through.
    }

    if (_parent case final RequestScopedRegistry registry) {
      if (registry.requestScopedFactory<T>() case final factory?) {
        final instance = factory();

        _cache[T] = instance;
        _created.add(instance);

        return instance;
      }
    }

    return _parent.get<T>();
  }

  @override
  void registerSingleton<T extends Object>(T instance) {
    _local.registerSingleton<T>(instance);
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _local.registerFactory<T>(factory);
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _local.registerLazySingleton<T>(factory);
  }

  @override
  void registerRequestScoped<T extends Object>(T Function() factory) {
    // Within a request there is no distinction between "scoped to the
    // request" and "built once here", so this is a lazy singleton.
    _local.registerLazySingleton<T>(factory);
  }
}
