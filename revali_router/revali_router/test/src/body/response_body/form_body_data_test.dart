import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(FormDataBodyData, () {
    test('should have correct mimeType', () {
      final formData = FormDataBodyData({'key': 'value'});
      expect(formData.mimeType, 'application/x-www-form-urlencoded');
    });

    test('should calculate correct contentLength', () {
      final formData = FormDataBodyData({'key': 'value'});
      expect(formData.contentLength, 'key=value'.length);
    });

    test('should encode data correctly', () async {
      final formData = FormDataBodyData({'key': 'value'});
      final result = await formData.read().first;
      expect(String.fromCharCodes(result), 'key=value');
    });

    test('should handle multiple key-value pairs', () async {
      final formData = FormDataBodyData({'key1': 'value1', 'key2': 'value2'});
      final result = await formData.read().first;
      expect(String.fromCharCodes(result), 'key1=value1&key2=value2');
    });

    test('should handle special characters', () async {
      final formData = FormDataBodyData({'key': 'value with spaces'});
      final result = await formData.read().first;
      expect(String.fromCharCodes(result), 'key=value+with+spaces');
    });

    test('should handle empty data', () async {
      final formData = FormDataBodyData({});
      final result = await formData.read().first;
      expect(String.fromCharCodes(result), '');
    });

    test('should create from JSON string', () {
      final formData = FormDataBodyData.fromString('{"key": "value"}');
      expect(formData.data, {'key': 'value'});
    });
  });
}
