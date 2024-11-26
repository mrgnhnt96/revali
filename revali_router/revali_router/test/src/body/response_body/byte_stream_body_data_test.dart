import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(ByteStreamBodyData, () {
    test('should have correct mimeType', () {
      final data = ByteStreamBodyData(const Stream.empty());
      expect(data.mimeType, 'application/octet-stream');
    });

    test('should return the correct contentLength', () {
      final data = ByteStreamBodyData(const Stream.empty(), contentLength: 100);
      expect(data.contentLength, 100);
    });

    test('should return the correct filename', () {
      final data =
          ByteStreamBodyData(const Stream.empty(), filename: 'test.txt');
      expect(data.filename, 'test.txt');
    });

    test('should cast data to Stream<List<int>>', () {
      const stream = Stream<List<int>>.empty();
      final data = ByteStreamBodyData(stream);
      expect(data.read(), isA<Stream<List<int>>>());
    });

    test('should return correct headers', () {
      final data = ByteStreamBodyData(
        const Stream.empty(),
        contentLength: 100,
        filename: 'test.txt',
      );
      final headers = data.headers(null);
      expect(headers.mimeType, 'application/octet-stream');
      expect(headers.filename, 'test.txt');
      expect(headers.contentLength, 100);
    });
  });
}
