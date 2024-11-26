import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(ListBodyData, () {
    test('should add a value to the list', () {
      final listBodyData = ListBodyData([])..add('test');
      expect(listBodyData.data, contains('test'));
    });

    test('should encode data to JSON and return as stream of bytes', () async {
      final listBodyData = ListBodyData(['test']);
      final stream = listBodyData.read();
      final result = await stream.first;
      expect(result, isNotEmpty);
    });

    test('should clear cache when a value is added', () {
      final listBodyData = ListBodyData([]);
      final data1 = listBodyData.toJson();

      listBodyData.add('test');
      final data2 = listBodyData.toJson();

      expect(data1, isNot(data2));
    });
  });
}
