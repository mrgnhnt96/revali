import 'package:mocktail/mocktail.dart';
import 'package:revali_router/src/access_control/expected_headers_impl.dart';
import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/router/router.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

void main() {
  group(Router, () {
    group('#routes', () {
      test('should return a list of routes', () {
        final router = Router(
          routes: const [],
        );

        expect(router.routes, isA<List<BaseRoute>>());
        expect(router.routes, isEmpty);
      });

      test('should return a list of routes with a single route', () {
        final route = BaseRoute('');

        final router = Router(
          routes: [route],
        );

        expect(router.routes, isA<List<BaseRoute>>());
        expect(router.routes, hasLength(1));
        expect(router.routes.single, route);
      });

      test('should return a list of routes with child', () {
        final child = BaseRoute('');

        final route = BaseRoute(
          'users',
          routes: [child],
        );

        final router = Router(
          routes: [route],
        );

        expect(router.routes, isA<List<BaseRoute>>());
        expect(router.routes, hasLength(1));

        final parent = router.routes.single;
        expect(parent, route);

        final parentRoutes = parent.routes?.toList();

        expect(parentRoutes, isA<List<BaseRoute>>());
        expect(parentRoutes, hasLength(1));
        expect(parentRoutes?.single, child);
      });

      test('should return a list of routes with children', () {
        final login = BaseRoute('a');
        final me = BaseRoute('b');
        final permissions = BaseRoute('c');

        final route = BaseRoute(
          'users',
          routes: [
            login,
            me,
            permissions,
          ],
        );

        final router = Router(
          routes: [route],
        );

        expect(router.routes, isA<List<BaseRoute>>());
        expect(router.routes, hasLength(1));

        final parent = router.routes.single;
        expect(parent, route);

        final parentRoutes = parent.routes?.toList();

        expect(parentRoutes, isA<List<BaseRoute>>());
        expect(parentRoutes, hasLength(3));
        expect(parentRoutes, containsAllInOrder([login, me, permissions]));
      });
    });

    group('#handle', () {
      group('should find route children', () {
        late Router router;
        late RequestContext mockRequestContext;

        Router setUpRouter() {
          final login = Route(
            'login',
            method: 'POST',
            handler: (_) async {},
          );
          final me = Route(
            'me',
            method: 'GET',
            expectedHeaders: const ExpectedHeadersImpl({'authorization'}),
            middlewares: const [_TestAuthMiddleware()],
            handler: (_) async {},
          );
          final permissions = Route(
            'permissions',
            method: 'GET',
            expectedHeaders: const ExpectedHeadersImpl({'authorization'}),
            handler: (_) async {},
          );

          final users = BaseRoute(
            'users',
            routes: [
              login,
              me,
              permissions,
            ],
          );

          final api = BaseRoute(
            'api',
            routes: [users],
          );

          return Router(
            routes: [api],
          );
        }

        setUp(() {
          router = setUpRouter();
          mockRequestContext = _MockRequest();
        });

        test('should find first child', () async {
          mockRequestContext.stub('api/users/permissions');

          final response = await router.handle(mockRequestContext);

          expect(response, isA<Response>());
        });
      });
    });
  });
}

class _MockRequest extends Mock implements RequestContext {}

class _MockUnderlyingRequest extends Mock implements UnderlyingRequest {}

extension _RequestContextX on RequestContext {
  void stub(
    String path, {
    String method = 'GET',
  }) {
    assert(path.isNotEmpty, 'Path cannot be empty');
    assert(method.isNotEmpty, 'Method cannot be empty');

    final instance = this;

    final uri = Uri.parse(path);
    when(() => instance.segments).thenReturn(uri.pathSegments);
    when(() => instance.method).thenReturn(method);
    when(() => instance.queryParameters).thenReturn(uri.queryParameters);
    when(() => instance.queryParametersAll).thenReturn(uri.queryParametersAll);
    when(() => instance.uri).thenReturn(uri);

    when(() => headers).thenReturn(HeadersImpl({}));

    final request = _MockUnderlyingRequest()..stub(uri, method: method);

    when(() => instance.request).thenReturn(request);
  }
}

extension _MockUnderlyingRequestX on UnderlyingRequest {
  void stub(
    Uri uri, {
    required String method,
  }) {
    final instance = this;

    when(() => instance.headers).thenReturn(HeadersImpl({}));
    when(() => instance.uri).thenReturn(uri);
    when(() => instance.method).thenReturn(method);
  }
}

class _TestAuthMiddleware implements Middleware {
  const _TestAuthMiddleware();

  @override
  Future<MiddlewareResult> use(Context context) async {
    return const MiddlewareResult.next();
  }
}
