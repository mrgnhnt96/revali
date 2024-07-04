abstract class ReadOnlyResponseContext {
  const ReadOnlyResponseContext();

  int get statusCode;
  Map<String, dynamic>? get body;

  Map<String, String> get headers;
}
