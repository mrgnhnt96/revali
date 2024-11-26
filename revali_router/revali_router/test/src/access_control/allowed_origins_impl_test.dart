import 'package:revali_router/src/access_control/allowed_origins_impl.dart';
import 'package:test/test.dart';

void main() {
  group(AllowedOriginsImpl, () {
    test(
        'should create an instance with given '
        'origins and inherit true by default', () {
      const origins = {'https://example.com', 'https://another.com'};
      const allowedOrigins = AllowedOriginsImpl(origins);

      expect(allowedOrigins.origins, equals(origins));
      expect(allowedOrigins.inherit, isTrue);
    });

    test('should create an instance with inherit set to false', () {
      const origins = {'https://example.com'};
      const allowedOrigins = AllowedOriginsImpl(origins, inherit: false);

      expect(allowedOrigins.origins, equals(origins));
      expect(allowedOrigins.inherit, isFalse);
    });

    test('should create an instance with all origins allowed', () {
      const allowedOrigins = AllowedOriginsImpl.all();

      expect(allowedOrigins.origins, equals({'*'}));
      expect(allowedOrigins.inherit, isFalse);
    });
  });
}
