import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:test/test.dart';

void main() {
  group(RouteMatch, () {
    RouteMatch match(String path) {
      return RouteMatch(Route(path));
    }

    group('#resolvePathParameters', () {
      test('should resolve path parameters when no parameters exist', () {
        final route = match('user');

        final result = route.resolvePathParameters(['user']);

        expect(result.pathParameters, isEmpty);
      });

      test('should resolve path parameters when one parameters exists', () {
        final route = match('user/:id');

        final result = route.resolvePathParameters(['user', '123']);

        expect(
          result.pathParameters,
          equals({
            'id': ['123'],
          }),
        );
      });

      test(
          'should resolve path parameters when '
          'multiple separated parameters exist', () {
        final route = match('user/:id/profile/:username');

        final result = route.resolvePathParameters([
          'user',
          '123',
          'profile',
          'mrgnhnt',
        ]);

        expect(
          result.pathParameters,
          equals({
            'id': ['123'],
            'username': ['mrgnhnt'],
          }),
        );
      });

      test(
          'should resolve path parameters when '
          'multiple consecutive parameters exist', () {
        final route = match('user/:id/:username');

        final result = route.resolvePathParameters([
          'user',
          '123',
          'mrgnhnt',
        ]);

        expect(
          result.pathParameters,
          equals({
            'id': ['123'],
            'username': ['mrgnhnt'],
          }),
        );
      });
    });
  });
}
