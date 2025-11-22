abstract class Cookies {
  const Cookies();

  void operator []=(String key, String? value);
  void remove(String key);
  void clear();
  void add(String key, String? value);

  Map<String, String?> get all;

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
