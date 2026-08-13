import 'package:revali_client/src/cookie_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CookieParser', () {
    test('reads a single cookie', () {
      expect(CookieParser('X-Auth=123').parse(), {'X-Auth': '123'});
    });

    test('drops attributes rather than storing them as cookies', () {
      // Regression: Path and Expires used to land in storage as if they were
      // cookies of their own.
      final parsed = CookieParser(
        'X-Auth=123; Path=/; HttpOnly; SameSite=Lax',
      ).parse();

      expect(parsed, {'X-Auth': '123'});
    });

    test('reads several cookies from one comma-joined header', () {
      // How package:http surfaces repeated Set-Cookie headers.
      final parsed = CookieParser(
        'X-Auth-Middleware=123, X-Auth-Pre=456, X-Auth-Post=789',
      ).parse();

      expect(parsed, {
        'X-Auth-Middleware': '123',
        'X-Auth-Pre': '456',
        'X-Auth-Post': '789',
      });
    });

    test('is not fooled by the comma inside an Expires date', () {
      final parsed = CookieParser(
        'a=1; Expires=Wed, 09 Jun 2021 10:18:14 GMT; Path=/, b=2; Path=/',
      ).parse();

      expect(parsed, {'a': '1', 'b': '2'});
    });

    test('keeps a value containing an equals sign intact', () {
      expect(CookieParser('token=abc==').parse(), {'token': 'abc=='});
    });

    test('accepts an empty value', () {
      expect(CookieParser('X-Auth=').parse(), {'X-Auth': ''});
    });

    test('ignores junk without a name', () {
      expect(CookieParser('=nonsense; ;').parse(), isEmpty);
    });

    test('ignores an empty header', () {
      expect(CookieParser('').parse(), isEmpty);
    });

    test('reads from several header values', () {
      final parsed = const CookieParser.all([
        'a=1; Path=/',
        'b=2; HttpOnly',
      ]).parse();

      expect(parsed, {'a': '1', 'b': '2'});
    });
  });
}
