import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group('JsonData', () {
    test('toJson returns correct JSON string', () {
      final data = {'key': 'value'};
      final jsonData = _MockJsonData(data);

      expect(jsonData.toJson(), '{"key":"value"}');
    });

    test('mimeType returns application/json', () {
      final data = {'key': 'value'};
      final jsonData = _MockJsonData(data);

      expect(jsonData.mimeType, 'application/json');
    });

    test('contentLength returns correct length', () {
      final data = {'key': 'value'};
      final jsonData = _MockJsonData(data);

      expect(jsonData.contentLength, '{"key":"value"}'.length);
    });

    test('headers returns correct headers', () {
      final data = {'key': 'value'};
      final jsonData = _MockJsonData(data);
      final headers = jsonData.headers(null);

      expect(headers.mimeType, 'application/json');
      expect(headers.contentLength, '{"key":"value"}'.length);
    });

    test('toJson caches the result', () {
      final data = {'key': 'value'};
      final jsonData = _MockJsonData(data);

      final json1 = jsonData.toJson();
      final json2 = jsonData.toJson();

      expect(json1, json2);
      expect(identical(json1, json2), isTrue);
    });
  });
}

base class _MockJsonData extends JsonData<Map<String, dynamic>> {
  _MockJsonData(super.data);

  @override
  Stream<List<int>>? read() {
    return null;
  }
}
