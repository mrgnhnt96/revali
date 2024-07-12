import 'dart:io';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/router.dart';
import 'package:test/test.dart';

void main() {
  group('$Router', () {
    late HttpRequest _fakeRequest;

    setUp(() {
      _fakeRequest = _FakeRequest();
    });

    group('#find', () {
      test('should return null if no routes are provided', () {
        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
          routes: [],
        );

        final result = router.find(
          segments: [],
          routes: null,
          method: 'GET',
        );

        expect(result?.route, isNull);
      });

      test('should return null if no routes match', () {
        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
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

        expect(result?.route, isNull);
      });

      test('should return the route if it matches', () {
        final getter = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
        );
        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
          routes: [getter],
        );

        final result = router.find(
          segments: ['user'],
          routes: router.routes,
          method: 'GET',
        );

        expect(result, isNotNull);
        expect(result?.route, getter);
      });

      test('should return the route if it matches and nested routes is empty',
          () {
        final getter = Route(
          'user',
          method: 'GET',
          handler: (_) async {},
          routes: [],
        );
        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
          routes: [getter],
        );

        final result = router.find(
          segments: ['user'],
          routes: router.routes,
          method: 'GET',
        );

        expect(result, isNotNull);
        expect(result?.route, getter);
      });

      test('should return nested route when matches', () {
        final create = Route(
          'create',
          method: 'POST',
          handler: (_) async {},
        );
        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
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
        expect(result?.route, create);
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
          RequestContextImpl.fromRequest(_fakeRequest),
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
        expect(result?.route, getter);
      });

      test('should return route when 1st nested empty path does not match', () {
        final post = Route(
          '',
          method: 'POST',
          handler: (_) async {},
        );

        final router = Router(
          RequestContextImpl.fromRequest(_fakeRequest),
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
        expect(result?.route, post);
      });

      group('single dynamic route', () {
        test('should return gracefully', () {
          final id = Route(
            ':id',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContextImpl.fromRequest(_fakeRequest),
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
          expect(result?.route, id);
        });

        test('should return correct route when preceded by dynamic route', () {
          final data = Route(
            'data',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContextImpl.fromRequest(_fakeRequest),
            routes: [
              Route(
                'user',
                method: 'GET',
                handler: (_) async {},
                routes: [
                  Route(
                    ':banana',
                    method: 'GET',
                    handler: (_) async {},
                  ),
                  data,
                ],
              ),
            ],
          );

          final result = router.find(
            segments: ['user', 'data'],
            routes: router.routes,
            method: 'GET',
          );

          expect(result, isNotNull);
          expect(result?.route, data);
        });

        test('should return correct complex route', () {
          final id = Route(
            ':id/boom',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContextImpl.fromRequest(_fakeRequest),
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
          expect(result?.route, id);
        });

        test('should return match with path parameters', () {
          final name = Route(
            ':name',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContextImpl.fromRequest(_fakeRequest),
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
                  Route(
                    ':id/boom',
                    method: 'GET',
                    handler: (_) async {},
                    routes: [name],
                  ),
                ],
              ),
            ],
          );

          final result = router.find(
            segments: ['user', '123', 'boom', 'bob'],
            routes: router.routes,
            method: 'GET',
          );

          expect(result, isNotNull);
          expect(result!.route, name);
          expect(result.pathParameters, {'id': '123', 'name': 'bob'});
        });

        test('should return nothing when root is not handled', () {
          final id = Route(
            ':id',
            method: 'GET',
            handler: (_) async {},
          );

          final router = Router(
            RequestContextImpl.fromRequest(_fakeRequest),
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

class _FakeRequest extends Fake implements HttpRequest {
  @override
  Future<List<Uint8List>> toList() {
    return Future.value([]);
  }

  @override
  HttpHeaders get headers => _FakeHeaders();
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  String? value(String name) {
    return null;
  }
}
