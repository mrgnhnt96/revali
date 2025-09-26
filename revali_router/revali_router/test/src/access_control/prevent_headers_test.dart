import 'package:revali_annotations/revali_annotations.dart';
import 'package:test/test.dart';

void main() {
  group(PreventHeaders, () {
    test('should create an instance with given headers and inherit flag', () {
      final headers = {'Content-Type', 'Authorization'};
      final allowedHeaders = PreventHeaders(headers, inherit: false);

      expect(allowedHeaders.headers, equals(headers));
      expect(allowedHeaders.inherit, isFalse);
    });

    test('should create an instance with default inherit flag as true', () {
      final headers = {'Content-Type', 'Authorization'};
      final allowedHeaders = PreventHeaders(headers);

      expect(allowedHeaders.headers, equals(headers));
      expect(allowedHeaders.inherit, isTrue);
    });

    test('should allow empty headers set', () {
      final headers = <String>{};
      final allowedHeaders = PreventHeaders(headers);

      expect(allowedHeaders.headers, isEmpty);
      expect(allowedHeaders.inherit, isTrue);
    });
  });
}
