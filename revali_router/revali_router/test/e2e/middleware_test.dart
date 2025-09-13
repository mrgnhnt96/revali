import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Middleware, () {
    test('runs gracefully', () async {
      final middleware = _SuccessMiddleware();

      await testRequest(
        TestRoute(
          middlewares: [middleware],
        ),
        verifyResponse: (response, context) {
          expect(middleware.wasCalled, isTrue);
        },
      );
    });

    test('runs in order', () async {
      final controller = StreamController<int>();

      await testRequest(
        TestRoute(
          middlewares: List.generate(
            5,
            (index) => _OrderedMiddleware(index, controller),
          ),
        ),
        verifyResponse: (response, context) {
          expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4]));
        },
      );
    });

    requestTest(
      'modifications persist throughout request',
      TestRoute(
        middlewares: [_ModifyingMiddleware()],
        handler: (context) async {
          expect(context.data.contains('Hello, World!'), isTrue);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body.data, 'Hello, World!');
        expect(response.headers['hello'], 'world');
        expect(context.request.headers['hello'], 'world');
      },
    );

    requestTest(
      'modifications can be overridden',
      TestRoute(
        middlewares: [_ModifyingMiddleware()],
        handler: (context) async {
          context.data.remove<String>();

          context.response.headers.remove('hello');
          context.request.headers.remove('hello');

          context.response.body = 'Goodbye, World!';

          context.response.headers['goodbye'] = 'world';
          context.request.headers['goodbye'] = 'world';

          expect(context.data.contains('Hello, World!'), isFalse);
          expect(context.data.has<String>(), isFalse);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body.data, 'Goodbye, World!');

        expect(response.headers['hello'], isNull);
        expect(context.request.headers['hello'], isNull);

        expect(response.headers['goodbye'], 'world');
        expect(context.request.headers['goodbye'], 'world');
      },
    );

    requestTest(
      'returning a response halts execution and overrides response',
      TestRoute(
        middlewares: const [_HaltingMiddleware.overrideResponse()],
      ),
      verifyResponse: (response, context) {
        expect(response.body.data, 'Overridden');
        expect(response.headers['overridden'], 'true');
        expect(response.statusCode, -1);
      },
    );

    requestTest(
      'returning a response halts execution and inherits existing response',
      TestRoute(
        middlewares: const [_HaltingMiddleware()],
      ),
      verifyResponse: (response, context) {
        expect(response.body.data, 'Not overridden');
        expect(response.headers['overridden'], 'false');
        expect(response.statusCode, 400);
      },
    );

    test('does not execute subsequent middleware if halted', () async {
      final successMiddleware = _SuccessMiddleware();

      await testRequest(
        TestRoute(
          middlewares: [
            const _HaltingMiddleware(),
            successMiddleware,
          ],
        ),
        verifyResponse: (response, context) {
          expect(successMiddleware.wasCalled, isFalse);
        },
      );
    });
  });
}

class _SuccessMiddleware implements Middleware {
  _SuccessMiddleware();

  bool wasCalled = false;

  @override
  Future<MiddlewareResult> use(Context context) async {
    wasCalled = true;
    return const MiddlewareResult.next();
  }
}

class _OrderedMiddleware implements Middleware {
  _OrderedMiddleware(this.index, this.controller);

  final int index;
  final StreamController<int> controller;

  @override
  Future<MiddlewareResult> use(Context context) async {
    controller.add(index);
    return const MiddlewareResult.next();
  }
}

class _ModifyingMiddleware implements Middleware {
  _ModifyingMiddleware();

  @override
  Future<MiddlewareResult> use(Context context) async {
    context.data.add('Hello, World!');
    context.response.body = 'Hello, World!';
    context.response.headers['hello'] = 'world';
    context.request.headers['hello'] = 'world';

    return const MiddlewareResult.next();
  }
}

class _HaltingMiddleware implements Middleware {
  const _HaltingMiddleware() : overrideResponse = false;
  const _HaltingMiddleware.overrideResponse() : overrideResponse = true;

  final bool overrideResponse;

  @override
  Future<MiddlewareResult> use(Context context) async {
    if (overrideResponse) {
      return const MiddlewareResult.stop(
        body: 'Overridden',
        headers: {'overridden': 'true'},
        statusCode: -1,
      );
    }

    context.response.body = 'Not overridden';
    context.response.headers['overridden'] = 'false';
    return const MiddlewareResult.stop();
  }
}
