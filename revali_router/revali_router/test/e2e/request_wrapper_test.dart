import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(RequestWrapper, () {
    test('runs before middleware, guard, interceptor, handler, and observer',
        () async {
      final controller = StreamController<String>();

      await testRequest(
        TestRoute(
          observers: [_Observer(controller)],
          requestWrappers: [_Wrapper(controller)],
          middlewares: [_Middleware(controller)],
          interceptors: [_Interceptor(controller)],
          guards: [_Guard(controller)],
          handler: (context) async {
            controller.add('Handler');
          },
        ),
        verifyResponse: (response, context) {
          expect(
            controller.stream,
            emitsInOrder([
              'Wrapper-pre',
              'Observer-pre',
              'Middleware',
              'Guard',
              'Interceptor-pre',
              'Handler',
              'Interceptor-post',
              'Wrapper-post',
              'Observer-post',
            ]),
          );
        },
      );
    });

    test('runs before middleware, guard, interceptor, and handler', () async {
      final controller = StreamController<String>();

      await testRequest(
        TestRoute(
          requestWrappers: [_Wrapper(controller)],
          middlewares: [_Middleware(controller)],
          interceptors: [_Interceptor(controller)],
          guards: [_Guard(controller)],
          handler: (context) async {
            controller.add('Handler');
          },
        ),
        verifyResponse: (response, context) {
          expect(
            controller.stream,
            emitsInOrder([
              'Wrapper-pre',
              'Middleware',
              'Guard',
              'Interceptor-pre',
              'Handler',
              'Interceptor-post',
              'Wrapper-post',
            ]),
          );
        },
      );
    });

    test('zone values are visible inside middleware and handler', () async {
      const zoneKey = #testZoneKey;
      const zoneValue = 'scoped-value';
      String? middlewareValue;
      String? handlerValue;

      await testRequest(
        TestRoute(
          requestWrappers: const [
            _ZoneWrapper(zoneKey: zoneKey, zoneValue: zoneValue),
          ],
          middlewares: [
            _ZoneReadingMiddleware(
              zoneKey: zoneKey,
              onValue: (value) => middlewareValue = value,
            ),
          ],
          handler: (context) async {
            handlerValue = Zone.current[zoneKey] as String?;
          },
        ),
        verifyResponse: (response, context) {
          expect(middlewareValue, zoneValue);
          expect(handlerValue, zoneValue);
        },
      );
    });

    test('runs without wrappers using handler zone guard behavior', () async {
      await testRequest(
        TestRoute(
          handler: (context) async {},
        ),
        verifyResponse: (response, context) {
          expect(response.statusCode, 200);
        },
      );
    });
  });
}

class _Wrapper implements RequestWrapper {
  _Wrapper(this.controller);

  final StreamController<String> controller;

  @override
  Future<Response> wrap(Context context, NextResponse next) async {
    controller.add('Wrapper-pre');
    try {
      return await next();
    } finally {
      controller.add('Wrapper-post');
    }
  }
}

class _ZoneWrapper implements RequestWrapper {
  const _ZoneWrapper({required this.zoneKey, required this.zoneValue});

  final Symbol zoneKey;
  final String zoneValue;

  @override
  Future<Response> wrap(Context context, NextResponse next) {
    return runZoned(
      next,
      zoneValues: {zoneKey: zoneValue},
    );
  }
}

class _ZoneReadingMiddleware implements Middleware {
  const _ZoneReadingMiddleware({
    required this.zoneKey,
    required this.onValue,
  });

  final Symbol zoneKey;
  final void Function(String? value) onValue;

  @override
  Future<MiddlewareResult> use(Context context) async {
    onValue(Zone.current[zoneKey] as String?);
    return const MiddlewareResult.next();
  }
}

class _Middleware implements Middleware {
  _Middleware(this.controller);

  final StreamController<String> controller;

  @override
  Future<MiddlewareResult> use(Context context) async {
    controller.add('Middleware');
    return const MiddlewareResult.next();
  }
}

class _Guard implements Guard {
  _Guard(this.controller);

  final StreamController<String> controller;

  @override
  Future<GuardResult> protect(Context context) async {
    controller.add('Guard');
    return const GuardResult.pass();
  }
}

class _Interceptor implements Interceptor {
  _Interceptor(this.controller);

  final StreamController<String> controller;

  @override
  Future<void> post(Context context) async {
    controller.add('Interceptor-post');
  }

  @override
  Future<void> pre(Context context) async {
    controller.add('Interceptor-pre');
  }
}

class _Observer implements Observer {
  _Observer(this.controller);

  final StreamController<String> controller;

  @override
  Future<void> see(
    Request request,
    Future<Response> response,
  ) async {
    controller.add('Observer-pre');
    await response;
    controller.add('Observer-post');
  }
}
