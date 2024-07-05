import 'package:revali_router/src/route/route.dart';
import 'package:test/test.dart';

void main() {
  group('$Route', () {
    group('constructor', () {
      test('should uppercase method', () {
        final route = Route(
          'user',
          method: 'get',
          handler: (_) async {},
        );

        expect(route.method, equals('GET'));
      });

      test('nested routes should have parent', () {
        final parent = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
          routes: [
            Route(
              'profile',
              method: 'GET',
              handler: (_) async {},
            ),
          ],
        );

        expect(parent.routes!.first.parent, equals(parent));
      });

      test('allows empty path', () {
        final route = Route(
          '',
          method: 'GET',
          handler: (_) async {},
        );

        expect(route.path, equals(''));
      });

      group('dynamic paths', () {
        test('should not conflict', () {
          final routes = [
            () => Route(
                  'user',
                  routes: [
                    Route(
                      ':id',
                      method: 'GET',
                      handler: (_) async {},
                    ),
                    Route(
                      ':name',
                      method: 'POST',
                      handler: (_) async {},
                    ),
                  ],
                ),
            () => Route(
                  'user/:id',
                  routes: [
                    Route(
                      ':name',
                      method: 'POST',
                      handler: (_) async {},
                    ),
                  ],
                ),
          ];

          // expect resolved
          for (final route in routes) {
            final result = route();

            expect(result, isNotNull);
          }
        });
      });

      group('should throw', () {
        test('if method is provided without handler', () {
          expect(
            () => Route(
              'user',
              method: 'GET',
            ),
            throwsArgumentError,
          );
        });

        test('if handler is provided without method', () {
          expect(
            () => Route(
              'user',
              handler: (_) async {},
            ),
            throwsArgumentError,
          );
        });

        test('if method is empty', () {
          expect(
            () => Route(
              'user',
              method: '',
              handler: (_) async {},
            ),
            throwsArgumentError,
          );
        });

        test('if path is empty and routes are provided', () {
          expect(
            () => Route(
              '',
              routes: [
                Route(
                  'user',
                  method: 'GET',
                  handler: (_) async {},
                ),
              ],
            ),
            throwsArgumentError,
          );
        });

        test('if path starts or ends with /', () {
          expect(
            () => Route(
              '/user',
              method: 'GET',
              handler: (_) async {},
            ),
            throwsArgumentError,
          );

          expect(
            () => Route(
              'user/',
              method: 'GET',
              handler: (_) async {},
            ),
            throwsArgumentError,
          );
        });

        test('if path contains special chars', () {
          const specials = {
            '!',
            '@',
            '#',
            '\$',
            '%',
            '^',
            '&',
            '*',
            '(',
            ')',
            ' ',
            '+',
            '=',
            '\t',
            '\n',
          };

          for (final special in specials) {
            expect(
              () => Route(
                'user$special',
                method: 'GET',
                handler: (_) async {},
              ),
              throwsArgumentError,
            );
          }
        });

        test('if path is not formatted correctly', () {
          const badFormat = {
            'user/:/id',
            'user./id',
            'user-/id',
            'user_/id',
            '-user/id',
            '_user/id',
            '.user/id',
          };

          for (final format in badFormat) {
            expect(
              () => Route(
                format,
                method: 'GET',
                handler: (_) async {},
              ),
              throwsArgumentError,
            );
          }
        });

        group('dynamic paths', () {
          test('when nested contains conflicting paths', () {
            final routes = [
              () => Route(
                    'user',
                    routes: [
                      Route(
                        ':id',
                        method: 'GET',
                        handler: (_) async {},
                      ),
                      Route(
                        ':name',
                        method: 'GET',
                        handler: (_) async {},
                      ),
                    ],
                  ),
            ];

            for (final route in routes) {
              expect(route, throwsArgumentError);
            }
          });
        });
      });
    });

    group('#getMeta', () {
      group('direct', () {
        test('should only return the direct meta', () {
          final route = Route(
            'user',
            method: 'GET',
            handler: (_) async {},
            meta: (m) => m..add(_Auth()),
            routes: [
              Route(
                'profile',
                method: 'GET',
                handler: (_) async {},
                meta: (m) => m..add(_Public()),
              ),
            ],
          );

          final child = route.routes!.first;

          final direct = child.getMeta(inherit: false);

          expect(direct.has<_Auth>(), isFalse);
          expect(direct.has<_Public>(), isTrue);
        });
      });

      group('inherit', () {
        test('should return only inherited meta', () {
          final route = Route(
            'user',
            method: 'GET',
            handler: (_) async {},
            meta: (m) => m..add(_Auth()),
            routes: [
              Route(
                'profile',
                method: 'GET',
                handler: (_) async {},
                meta: (m) => m..add(_Public()),
              ),
            ],
          );

          final child = route.routes!.first;

          final inherited = child.getMeta(inherit: true);

          expect(inherited.has<_Auth>(), isTrue);
          expect(inherited.has<_Public>(), isFalse);
        });
      });
    });
  });
}

class _Auth {}

class _Public {}
