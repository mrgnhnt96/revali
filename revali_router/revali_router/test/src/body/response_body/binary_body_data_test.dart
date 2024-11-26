import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(BinaryBodyData, () {
    test('should have correct mimeType', () {
      final data = BinaryBodyData([
        [1, 2, 3],
      ]);
      expect(data.mimeType, 'application/octet-stream');
    });

    test('should calculate contentLength correctly', () {
      final data = BinaryBodyData([
        [1, 2, 3, 4, 5],
      ]);
      expect(data.contentLength, 5);
    });

    test('should read data as stream', () async {
      final data = BinaryBodyData([
        [1, 2, 3],
      ]);
      final result = await data.read().toList();
      expect(result, [
        [1, 2, 3],
      ]);
    });

    test('should generate correct headers', () {
      final data = BinaryBodyData([
        [1, 2, 3],
      ]);
      final headers = data.headers(null);
      expect(headers.contentLength, 3);
      expect(headers.mimeType, 'application/octet-stream');
    });
  });
}
