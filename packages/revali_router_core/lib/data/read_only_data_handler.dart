abstract class ReadOnlyDataHandler {
  const ReadOnlyDataHandler();

  T? get<T>();

  bool has<T>();
}
