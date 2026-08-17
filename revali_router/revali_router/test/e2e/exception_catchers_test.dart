import 'dart:io';

import 'package:revali_core/revali_core.dart';
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
          expect(response.body.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(6));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
          expect(headers['access-control-allow-origin'], '*');
          expect(headers['access-control-allow-credentials'], 'true');
          expect(headers['access-control-allow-methods'], 'OPTIONS, GET, HEAD');
          expect(headers['allow'], 'OPTIONS, GET, HEAD');
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
          expect(response.body.data, 'Internal Server Error');
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
          expect(response.body.data, 'Internal Server Error');
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
          expect(response.body.data, 'Internal Server Error');
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
          expect(response.body.data, 'Internal Server Error');
          final headers = response.joinedHeaders;

          expect(headers.keys, hasLength(2));
          expect(headers['content-type'], 'text/plain');
          expect(headers['content-length'], '21');
        },
      );
    });

    // Every test above returns a bare `handled()`, so the generic 500 they
    // assert is the right answer -- the catcher said nothing about the
    // response. These cover the other half: a catcher that did. `debug` is
    // absent from a released build, and a 5xx the app wrote is not a crash to
    // be hidden.
    group('with overrides of its own', () {
      test('keeps the status it chose', () async {
        final catcher = _ShedCatcher();

        await testRequest(
          TestRoute(
            catchers: [catcher],
            handler: (context) async {
              throw _TestException();
            },
          ),
          verifyResponse: (response, context) {
            expect(catcher.wasCalled, isTrue);

            expect(response.statusCode, HttpStatus.serviceUnavailable);
            expect(response.body.data, {'error': 'shedding'});
          },
        );
      });

      test('keeps a body it wrote under the fallback status', () async {
        final catcher = _BodyOnlyCatcher();

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
            expect(response.body.data, {'error': 'saturated'});
          },
        );
      });
    });
  });
}

class _TestException implements Exception {}

base class _Catcher extends ExceptionCatcher<_TestException> {
  bool wasCalled = false;

  @override
  ExceptionCatcherResult<_TestException> catchException(
    _TestException exception,
    Context context,
  ) {
    wasCalled = true;
    return const ExceptionCatcherResult.handled();
  }
}

/// Sheds load with a status of its own -- the shape that used to be replaced.
base class _ShedCatcher extends ExceptionCatcher<_TestException> {
  bool wasCalled = false;

  @override
  ExceptionCatcherResult<_TestException> catchException(
    _TestException exception,
    Context context,
  ) {
    wasCalled = true;
    return const ExceptionCatcherResult.handled(
      statusCode: HttpStatus.serviceUnavailable,
      body: {'error': 'shedding'},
    );
  }
}

/// Writes an envelope but leaves the status to the framework.
base class _BodyOnlyCatcher extends ExceptionCatcher<_TestException> {
  bool wasCalled = false;

  @override
  ExceptionCatcherResult<_TestException> catchException(
    _TestException exception,
    Context context,
  ) {
    wasCalled = true;
    return const ExceptionCatcherResult.handled(
      body: {'error': 'saturated'},
    );
  }
}

class _ThrowMiddleware implements Middleware {
  bool wasCalled = false;

  @override
  Future<MiddlewareResult> use(Context context) {
    wasCalled = true;
    throw _TestException();
  }
}

class _ThrowGuard implements Guard {
  bool wasCalled = false;

  @override
  Future<GuardResult> protect(Context context) {
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
  Future<void> post(Context context) async {
    postWasCalled = true;
    if (inPost) {
      throw _TestException();
    }
  }

  @override
  Future<void> pre(Context context) async {
    preWasCalled = true;
    if (inPre) {
      throw _TestException();
    }
  }
}
