abstract class ReadOnlyMeta {
  const ReadOnlyMeta();

  List<T>? get<T>();

  bool has<T>();
}
