abstract class WriteOnlyDataHandler {
  const WriteOnlyDataHandler();

  void add<T>(T instance);

  bool remove<T>();
}
