abstract class ReadOnlyRequestContext {
  const ReadOnlyRequestContext();

  Map<String, String> get headers;

  Future<String?> get body;
}
