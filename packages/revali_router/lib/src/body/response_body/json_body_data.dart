part of 'base_body_data.dart';

final class JsonBodyData extends JsonData<Map<String, dynamic>> {
  JsonBodyData(super.data);

  void operator []=(String key, Object? value) {
    data[key] = value;
    _clearCache();
  }

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(toJson()));
  }
}
