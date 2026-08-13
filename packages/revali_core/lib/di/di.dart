import 'package:revali_core/di/disposable.dart';

typedef Factory<T> = T Function();

abstract class DI {
  const DI();

  void registerSingleton<T extends Object>(T instance);

  void registerFactory<T extends Object>(T Function() factory);

  /// Registers a dependency built once **per request** and shared for the
  /// rest of it.
  ///
  /// Unlike [registerFactory], which builds a new instance at every
  /// resolution, everything resolving `T` within one request gets the same
  /// instance — so a unit of work, a transaction, or the identity of the
  /// caller can be threaded through middleware, guards and the handler
  /// without passing it by hand.
  ///
  /// Unlike [registerSingleton], nothing is shared *between* requests.
  ///
  /// If the instance implements [Disposable] it is disposed when the request
  /// ends. Resolving `T` outside a request throws.
  void registerRequestScoped<T extends Object>(T Function() factory);

  void registerLazySingleton<T extends Object>(T Function() factory);

  T get<T extends Object>();
}
