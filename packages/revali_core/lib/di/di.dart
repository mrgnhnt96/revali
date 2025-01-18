typedef Factory<T> = T Function();

abstract class DI {
  const DI();

  void registerInstance<T extends Object>(T instance);

  void register<T extends Object>(T Function() factory);

  T get<T extends Object>();
}
