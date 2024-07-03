abstract class MutableResponseContext {
  const MutableResponseContext();

  void setHeader(String key, String value);

  void removeHeader(String key);
}
