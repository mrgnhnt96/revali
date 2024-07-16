typedef Factory<T> = T Function();

abstract class DI {
  const DI();

  void registerInstance<T>(T instance);

  void register<T>(Factory<T> factory);
}
