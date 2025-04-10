typedef Factory<T> = T Function();

abstract class DI {
  const DI();

  @Deprecated('Use registerSingleton instead')
  void registerInstance<T extends Object>(T instance);

  void registerSingleton<T extends Object>(T instance);

  @Deprecated('Use registerFactory or registerLazySingleton instead')
  void register<T extends Object>(T Function() factory);

  void registerFactory<T extends Object>(T Function() factory);

  void registerLazySingleton<T extends Object>(T Function() factory);

  T get<T extends Object>();
}
