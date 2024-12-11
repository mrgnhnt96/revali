abstract class WriteOnlyData {
  const WriteOnlyData();

  void add<T>(T instance);

  bool remove<T>();
}
