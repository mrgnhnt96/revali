import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(JsonBodyData, () {
    test('should initialize with given data', () {
      final data = {'key': 'value'};
      final jsonBodyData = JsonBodyData(data);

      expect(jsonBodyData.data, equals(data));
    });

    test('should update data using operator []=', () {
      final data = {'key': 'value'};
      final jsonBodyData = JsonBodyData(data);

      jsonBodyData['newKey'] = 'newValue';

      expect(jsonBodyData.data['newKey'], equals('newValue'));
    });

    test('should clear cache when data is updated', () {
      final data = {'key': 'value'};
      final jsonBodyData = JsonBodyData(data);

      jsonBodyData['newKey'] = 'newValue';

      expect(jsonBodyData.data['newKey'], equals('newValue'));
    });

    test('should read data as a stream of encoded JSON', () async {
      final data = {'key': 'value'};
      final jsonBodyData = JsonBodyData(data);

      final stream = jsonBodyData.read();
      final result = await stream.first;

      expect(
        result,
        equals(jsonBodyData.encoding.encode(jsonBodyData.toJson())),
      );
    });
  });
}
