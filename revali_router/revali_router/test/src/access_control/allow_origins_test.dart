import 'package:revali_annotations/revali_annotations.dart';
import 'package:test/test.dart';

void main() {
  group(AllowOrigins, () {
    test(
        'should create an instance with given '
        'origins and inherit true by default', () {
      const origins = {'https://example.com', 'https://another.com'};
      const allowedOrigins = AllowOrigins(origins);

      expect(allowedOrigins.origins, equals(origins));
      expect(allowedOrigins.inherit, isTrue);
    });

    test('should create an instance with inherit set to false', () {
      const origins = {'https://example.com'};
      const allowedOrigins = AllowOrigins(origins, inherit: false);

      expect(allowedOrigins.origins, equals(origins));
      expect(allowedOrigins.inherit, isFalse);
    });

    test('should create an instance with all origins allowed', () {
      const allowedOrigins = AllowOrigins.all();

      expect(allowedOrigins.origins, equals({'*'}));
      expect(allowedOrigins.inherit, isFalse);
    });
  });
}
