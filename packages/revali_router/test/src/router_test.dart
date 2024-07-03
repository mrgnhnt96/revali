import 'package:mockito/mockito.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/router.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('$Router', () {
    late Request _fakeRequest;

    setUp(() {
      _fakeRequest = _FakeRequest();
    });

    group('#find', () {
      test('should return null if no routes are provided', () {
        final router = Router(
          RequestContext(_fakeRequest),
          routes: [],
        );

        final result = router.find(
          segments: [],
          routes: null,
          method: 'GET',
        );

        expect(result, isNull);
      });

      test('should return null if no routes match', () {
        final router = Router(
          RequestContext(_fakeRequest),
          routes: [
            Route(
              'user',
              method: 'GET',
              handler: (_) async {},
            ),
          ],
        );

        final result = router.find(
          segments: ['not-user'],
          routes: router.routes,
          method: 'GET',
        );

        expect(result, isNull);
      });

      test('should return the route if it matches', () {
        final getter = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
        );
        final router = Router(
          RequestContext(_fakeRequest),
          routes: [getter],
        );

        final result = router.find(
          segments: ['user'],
          routes: router.routes,
          method: 'GET',
        );

        expect(result, isNotNull);
        expect(result, getter);
      });

      test('should return nested route when matches', () {
        final create = Route(
          'create',
          method: 'POST',
          handler: (_) async {},
        );
        final router = Router(
          RequestContext(_fakeRequest),
          routes: [
            Route(
              'user',
              method: 'GET',
              handler: (_) async {},
              routes: [create],
            ),
          ],
        );

        final result = router.find(
          segments: ['user', 'create'],
          routes: router.routes,
          method: 'POST',
        );

        expect(result, isNotNull);
        expect(result, create);
      });

      test(
          'should return nested route when root is '
          'not invokable and child path is empty', () {
        final getter = Route(
          '',
          method: 'GET',
          handler: (_) async {},
        );
        final router = Router(
          RequestContext(_fakeRequest),
          routes: [
            Route(
              'user',
              handler: null,
              routes: [getter],
            ),
          ],
        );

        final result = router.find(
          segments: ['user'],
          routes: router.routes,
          method: 'GET',
        );

        expect(result, isNotNull);
        expect(result, getter);
      });

      test('should return route when 1st nested empty path does not match', () {
        final post = Route(
          '',
          method: 'POST',
          handler: (_) async {},
        );

        final router = Router(
          RequestContext(_fakeRequest),
          routes: [
            Route(
              'user',
              handler: null,
              routes: [
                Route(
                  '',
                  method: 'GET',
                  handler: (_) async {},
                ),
                post,
              ],
            ),
          ],
        );

        final result = router.find(
          segments: ['user'],
          routes: router.routes,
          method: 'POST',
        );

        expect(result, isNotNull);
        expect(result, post);
      });

      group('single dynamic route', () {
        test('should return gracefully', () {
          final id = Route(
            ':id',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContext(_fakeRequest),
            routes: [
              Route(
                'user',
                method: 'GET',
                handler: (_) async {},
                routes: [id],
              ),
            ],
          );

          final result = router.find(
            segments: ['user', '123'],
            routes: router.routes,
            method: 'GET',
          );

          expect(result, isNotNull);
          expect(result, id);
        });

        test('should return correct route', () {
          final id = Route(
            ':id/boom',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContext(_fakeRequest),
            routes: [
              Route(
                'user',
                method: 'GET',
                handler: (_) async {},
                routes: [
                  Route(
                    ':banana/data',
                    method: 'GET',
                    handler: (_) async {},
                  ),
                  Route(
                    'data/:id',
                    method: 'GET',
                    handler: (_) async {},
                  ),
                  id,
                ],
              ),
            ],
          );

          final result = router.find(
            segments: ['user', '123', 'boom'],
            routes: router.routes,
            method: 'GET',
          );

          expect(result, isNotNull);
          expect(result, id);
        });

        test('should return nothing when root is not handled', () {
          final id = Route(
            ':id',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContext(_fakeRequest),
            routes: [
              Route(
                'user',
                routes: [id],
              ),
            ],
          );

          final result = router.find(
            segments: ['user'],
            routes: router.routes,
            method: 'GET',
          );

          expect(result, isNull);
        });
      });
    });
  });
}

class _FakeRequest extends Fake implements Request {
  @override
  Map<String, String> get headers => const {};
}
