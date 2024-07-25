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
        test('if root handler and nested empty route handler is implemented',
            () {
          expect(
            () => Route(
              '',
              method: 'GET',
              handler: (_) async {},
              routes: [
                Route(
                  '',
                  method: 'GET',
                  handler: (_) async {},
                ),
              ],
            ),
            throwsArgumentError,
          );
        });

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
            r'$',
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

    group('#allowedMethods', () {
      test('should return GET and HEAD for GET route', () {
        final getter = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
        );

        final result = getter.allowedMethods;

        expect(result, containsAll(['GET', 'HEAD']));
      });

      test('should only return sibling methods', () {
        final getter = Route(
          ':id',
          method: 'GET',
          handler: (_) async {},
        );

        final poster = Route(
          ':id',
          method: 'POST',
          handler: (_) async {},
        );

        final parent = Route(
          'user',
          routes: [getter, poster],
        );

        final result = parent.routes!.first.allowedMethods;

        expect(result, ['OPTIONS', 'GET', 'HEAD', 'POST']);
      });

      test('should not return non-matching siblings', () {
        final getter = Route(
          'some',
          method: 'GET',
          handler: (_) async {},
        );

        final poster = Route(
          'thing',
          method: 'POST',
          handler: (_) async {},
        );

        final parent = Route(
          'user',
          routes: [getter, poster],
        );

        final result = parent.routes!.last.allowedMethods;

        expect(result, ['OPTIONS', 'POST']);
      });
    });

    group('#matchesPath', () {
      test('should match simple route', () {
        final route = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
        );

        final result = route.matchesPath(Route('user'));

        expect(result, isTrue);
      });

      test('should match dynamic route', () {
        final route = Route(
          ':id',
          method: 'GET',
          handler: (_) async {},
        );

        final result = route.matchesPath(Route('123'));

        expect(result, isTrue);
      });

      test('should match multiple simple segments', () {
        final route = Route(
          'user/profile',
          method: 'GET',
          handler: (_) async {},
        );

        final result = route.matchesPath(Route('user/profile'));

        expect(result, isTrue);
      });

      test('should match multiple complex segments', () {
        final route = Route(
          'user/:id/profile',
          method: 'GET',
          handler: (_) async {},
        );

        final result = route.matchesPath(Route('user/123/profile'));

        expect(result, isTrue);
      });

      test('should not match different paths', () {
        final route = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
        );

        final result = route.matchesPath(Route('profile'));

        expect(result, isFalse);
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

          final direct = child.getMeta();

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
