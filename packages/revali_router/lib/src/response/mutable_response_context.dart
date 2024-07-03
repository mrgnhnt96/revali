abstract class MutableResponseContext {
  const MutableResponseContext();

  void setHeader(String key, String value);

  void removeHeader(String key);

  int get statusCode;
  void set statusCode(int value);

  Object? get body;

  /// The value to be set as the body of the response
  ///
  /// The body will be nested under the `data` key in the response
  void set body(Object? value);

  /// The value to be set as the body of the response
  ///
  /// The key CANNOT be `data` as it is reserved for the body
  void addToBody(String key, Object value);
}
