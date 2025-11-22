import 'package:revali_annotations/revali_annotations.dart';
import 'package:test/test.dart';

void main() {
  group(ExpectHeaders, () {
    test('should create an instance with given headers', () {
      const headers = {'Content-Type', 'Authorization'};
      const expectedHeaders = ExpectHeaders(headers);

      expect(expectedHeaders.headers, equals(headers));
    });

    test('should return an empty set when no headers are provided', () {
      const headers = <String>{};
      const expectedHeaders = ExpectHeaders(headers);

      expect(expectedHeaders.headers, isEmpty);
    });

    test('should contain the correct headers', () {
      const headers = {'Accept', 'User-Agent'};
      const expectedHeaders = ExpectHeaders(headers);

      expect(expectedHeaders.headers.contains('Accept'), isTrue);
      expect(expectedHeaders.headers.contains('User-Agent'), isTrue);
    });

    test('should not contain headers that were not provided', () {
      const headers = {'X-Custom-Header'};
      const expectedHeaders = ExpectHeaders(headers);

      expect(expectedHeaders.headers.contains('Authorization'), isFalse);
    });
  });
}
