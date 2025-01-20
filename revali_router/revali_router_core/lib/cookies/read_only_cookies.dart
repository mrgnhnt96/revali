abstract class ReadOnlyCookies {
  const ReadOnlyCookies();

  String? operator [](String key);
  List<MapEntry<String, String?>> get entries;
  List<String> get values;
  List<String> get keys;

  bool containsKey(String key);

  String headerValue();
  String get headerKey;

  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
}
