import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group('ExceptionCatcher', () {
    test('catches during handler', () async {
      final catcher = _Catcher();

      await testRequest(
        TestRoute(
          catchers: [catcher],
          handler: (context) async {
            throw _TestException();
          },
        ),
        verifyResponse: (response, context) {
          expect(catcher.wasCalled, isTrue);

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(response.body?.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });

    test('catches during middleware', () async {
      final catcher = _Catcher();
      final middleware = _ThrowMiddleware();

      await testRequest(
        TestRoute(
          middlewares: [middleware],
          catchers: [catcher],
        ),
        verifyResponse: (response, context) {
          expect(catcher.wasCalled, isTrue);
          expect(middleware.wasCalled, isTrue);

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(response.body?.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });

    test('catches during guard', () async {
      final catcher = _Catcher();
      final guard = _ThrowGuard();

      await testRequest(
        TestRoute(
          guards: [guard],
          catchers: [catcher],
        ),
        verifyResponse: (response, context) {
          expect(catcher.wasCalled, isTrue);
          expect(guard.wasCalled, isTrue);

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(response.body?.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });

    test('catches during pre interceptor', () async {
      final interceptor = _ThrowInterceptor(inPre: true, inPost: false);

      await testRequest(
        TestRoute(
          interceptors: [interceptor],
        ),
        verifyResponse: (response, context) {
          expect(interceptor.preWasCalled, isTrue);
          expect(interceptor.postWasCalled, isFalse);

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(response.body?.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });

    test('catches during post interceptor', () async {
      final interceptor = _ThrowInterceptor(inPre: false, inPost: true);

      await testRequest(
        TestRoute(
          interceptors: [interceptor],
        ),
        verifyResponse: (response, context) {
          expect(interceptor.preWasCalled, isTrue);
          expect(interceptor.postWasCalled, isTrue);

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(response.body?.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });
  });
}

class _TestException implements Exception {}

base class _Catcher extends ExceptionCatcher<_TestException> {
  bool wasCalled = false;

  @override
  ExceptionCatcherResult catchException(
    _TestException exception,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  ) {
    wasCalled = true;
    return action.handled();
  }
}

class _ThrowMiddleware implements Middleware {
  bool wasCalled = false;

  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  ) {
    wasCalled = true;
    throw _TestException();
  }
}

class _ThrowGuard implements Guard {
  bool wasCalled = false;

  @override
  Future<GuardResult> canActivate(
    GuardContext context,
    GuardAction canActivate,
  ) {
    wasCalled = true;
    throw _TestException();
  }
}

class _ThrowInterceptor implements Interceptor {
  _ThrowInterceptor({
    required this.inPre,
    required this.inPost,
  });

  final bool inPre;
  final bool inPost;

  bool preWasCalled = false;
  bool postWasCalled = false;

  @override
  Future<void> post(FullInterceptorContext context) async {
    postWasCalled = true;
    if (inPost) {
      throw _TestException();
    }
  }

  @override
  Future<void> pre(RestrictedInterceptorContext context) async {
    preWasCalled = true;
    if (inPre) {
      throw _TestException();
    }
  }
}
