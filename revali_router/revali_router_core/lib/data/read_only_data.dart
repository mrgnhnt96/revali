abstract class ReadOnlyData {
  const ReadOnlyData();

  T? get<T>();

  bool has<T>();

  bool contains<T>(T value);
}
