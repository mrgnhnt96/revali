import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(LifecycleComponents, () {
    test('executes in the proper order', () async {
      final controller = StreamController<String>();

      await testRequest(
        TestRoute(
          observers: [_Observer(controller)],
          interceptors: [_Interceptor(controller)],
          guards: [_Guard(controller)],
          middlewares: [_Middleware(controller)],
          handler: (context) async {
            controller.add('Handler');
          },
        ),
        verifyResponse: (response, context) {
          expect(
            controller.stream,
            emitsInOrder([
              'Observer-pre',
              'Middleware',
              'Guard',
              'Interceptor-pre',
              'Handler',
              'Interceptor-post',
              'Observer-post',
            ]),
          );
        },
      );
    });
  });
}

class _Middleware implements Middleware {
  _Middleware(this.controller);

  final StreamController<String> controller;

  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  ) async {
    controller.add('Middleware');
    return action.next();
  }
}

class _Guard implements Guard {
  _Guard(this.controller);

  final StreamController<String> controller;

  @override
  Future<GuardResult> canActivate(
    GuardContext context,
    GuardAction canActivate,
  ) async {
    controller.add('Guard');

    return canActivate.yes();
  }
}

class _Interceptor implements Interceptor {
  _Interceptor(this.controller);

  final StreamController<String> controller;

  @override
  Future<void> post(FullInterceptorContext context) async {
    controller.add('Interceptor-post');
  }

  @override
  Future<void> pre(RestrictedInterceptorContext context) async {
    controller.add('Interceptor-pre');
  }
}

class _Observer implements Observer {
  _Observer(this.controller);

  final StreamController<String> controller;

  @override
  Future<void> see(
    ReadOnlyRequest request,
    Future<ReadOnlyResponse> response,
  ) async {
    controller.add('Observer-pre');
    await response;
    controller.add('Observer-post');
  }
}
