import 'package:revali_router/src/access_control/expected_headers_impl.dart';
import 'package:test/test.dart';

void main() {
  group(ExpectedHeadersImpl, () {
    test('should create an instance with given headers', () {
      const headers = {'Content-Type', 'Authorization'};
      const expectedHeaders = ExpectedHeadersImpl(headers);

      expect(expectedHeaders.headers, equals(headers));
    });

    test('should return an empty set when no headers are provided', () {
      const headers = <String>{};
      const expectedHeaders = ExpectedHeadersImpl(headers);

      expect(expectedHeaders.headers, isEmpty);
    });

    test('should contain the correct headers', () {
      const headers = {'Accept', 'User-Agent'};
      const expectedHeaders = ExpectedHeadersImpl(headers);

      expect(expectedHeaders.headers.contains('Accept'), isTrue);
      expect(expectedHeaders.headers.contains('User-Agent'), isTrue);
    });

    test('should not contain headers that were not provided', () {
      const headers = {'X-Custom-Header'};
      const expectedHeaders = ExpectedHeadersImpl(headers);

      expect(expectedHeaders.headers.contains('Authorization'), isFalse);
    });
  });
}
