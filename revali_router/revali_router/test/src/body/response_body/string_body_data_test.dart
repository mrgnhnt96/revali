import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(StringBodyData, () {
    test('should return correct mimeType', () {
      const data = 'Hello, World!';
      final stringBodyData = StringBodyData(data);

      expect(stringBodyData.mimeType, 'text/plain');
    });

    test('should return correct contentLength', () {
      const data = 'Hello, World!';
      final stringBodyData = StringBodyData(data);

      expect(stringBodyData.contentLength, data.length);
    });

    test('should return correct encoded data stream', () async {
      const data = 'Hello, World!';
      final stringBodyData = StringBodyData(data);
      final encodedData = await stringBodyData.read().first;

      expect(encodedData, data.codeUnits);
    });

    test('should return correct headers', () {
      const data = 'Hello, World!';
      final stringBodyData = StringBodyData(data);
      final headers = stringBodyData.headers(null);

      expect(headers.mimeType, 'text/plain');
      expect(headers.contentLength, data.length);
    });
  });
}
