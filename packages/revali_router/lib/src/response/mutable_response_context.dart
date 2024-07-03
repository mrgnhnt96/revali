abstract class MutableResponseContext {
  const MutableResponseContext();

  void setHeader(String key, String value);

  void removeHeader(String key);

  int get statusCode;
  void set statusCode(int value);

  Object? get body;
  void set body(Object? value);
}
