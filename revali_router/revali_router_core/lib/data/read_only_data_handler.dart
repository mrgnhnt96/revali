abstract class ReadOnlyDataHandler {
  const ReadOnlyDataHandler();

  T? get<T>();

  bool has<T>();

  bool contains<T>(T value);
}
