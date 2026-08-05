import 'package:revali_router/src/cookies/set_cookies_impl.dart';
import 'package:test/test.dart';

void main() {
  group(SetCookiesImpl, () {
    test('headerValues is empty when no cookies are set', () {
      final setCookies = SetCookiesImpl();

      expect(setCookies.headerValues(), isEmpty);
    });

    test('headerValues emits one string per cookie, not one joined string', () {
      final setCookies = SetCookiesImpl()
        ..['a'] = '1'
        ..['b'] = '2';

      final values = setCookies.headerValues();

      expect(values, hasLength(2));
      expect(values, everyElement(isNot(contains(RegExp('a=1.*b=2')))));
    });

    test('each cookie carries the shared attributes', () {
      final setCookies = SetCookiesImpl()
        ..['a'] = '1'
        ..['b'] = '2'
        ..path = '/api'
        ..secure = true;

      final values = setCookies.headerValues();

      expect(values, hasLength(2));
      for (final value in values) {
        expect(value, contains('Path=/api'));
        expect(value, contains('Secure'));
      }
      expect(values.any((v) => v.startsWith('a=1;')), isTrue);
      expect(values.any((v) => v.startsWith('b=2;')), isTrue);
    });

    test('a single cookie has no trailing separator artifacts', () {
      final setCookies = SetCookiesImpl()..['only'] = 'value';

      final values = setCookies.headerValues();

      expect(values, ['only=value; Secure; HttpOnly; SameSite=Lax; Path=/']);
    });
  });
}
