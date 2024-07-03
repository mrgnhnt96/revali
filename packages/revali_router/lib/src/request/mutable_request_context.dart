abstract class MutableRequestContext {
  const MutableRequestContext();

  void setHeader(String key, String value);

  void removeHeader(String key);
}
