part of 'base_body_data.dart';

final class ListBodyData extends JsonData<List<dynamic>> {
  ListBodyData(super.data);

  void add(Object? value) {
    data.add(value);
    _clearCache();
  }

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(toJson()));
  }
}
