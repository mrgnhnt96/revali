import 'package:revali_router/src/access_control/allowed_headers_impl.dart';
import 'package:test/test.dart';

void main() {
  group(AllowedHeadersImpl, () {
    test('should create an instance with given headers and inherit flag', () {
      final headers = {'Content-Type', 'Authorization'};
      final allowedHeaders = AllowedHeadersImpl(headers, inherit: false);

      expect(allowedHeaders.headers, equals(headers));
      expect(allowedHeaders.inherit, isFalse);
    });

    test('should create an instance with default inherit flag as true', () {
      final headers = {'Content-Type', 'Authorization'};
      final allowedHeaders = AllowedHeadersImpl(headers);

      expect(allowedHeaders.headers, equals(headers));
      expect(allowedHeaders.inherit, isTrue);
    });

    test('should allow empty headers set', () {
      final headers = <String>{};
      final allowedHeaders = AllowedHeadersImpl(headers);

      expect(allowedHeaders.headers, isEmpty);
      expect(allowedHeaders.inherit, isTrue);
    });
  });
}
