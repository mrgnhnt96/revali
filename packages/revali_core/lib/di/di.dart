typedef Factory<T> = T Function();

abstract class DI {
  const DI();

  void registerSingleton<T extends Object>(T instance);

  void registerFactory<T extends Object>(T Function() factory);

  void registerLazySingleton<T extends Object>(T Function() factory);

  T get<T extends Object>();
}
