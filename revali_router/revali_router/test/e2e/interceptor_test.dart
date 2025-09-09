import 'dart:async';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Interceptor, () {
    test('runs gracefully', () async {
      final interceptor = _SuccessInterceptor();

      await testRequest(
        TestRoute(
          interceptors: [interceptor],
        ),
        verifyResponse: (response, context) {
          expect(interceptor.preWasCalled, isTrue);
          expect(interceptor.postWasCalled, isTrue);
        },
      );
    });

    test('runs in order', () async {
      final controller = StreamController<String>();

      await testRequest(
        TestRoute(
          interceptors: List.generate(
            5,
            (index) => _OrderedInterceptor(index, controller),
          ),
        ),
        verifyResponse: (response, context) {
          expect(
            controller.stream,
            emitsInOrder([
              'pre-0',
              'pre-1',
              'pre-2',
              'pre-3',
              'pre-4',
              'post-4',
              'post-3',
              'post-2',
              'post-1',
              'post-0',
            ]),
          );
        },
      );
    });

    requestTest(
      'modifications persist throughout request',
      TestRoute(
        interceptors: [_ModifyingInterceptor()],
        handler: (context) async {
          expect(context.data.contains('Hello, World!'), isTrue);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Goodbye, World!');
        expect(response.headers['pre'], 'hello');
        expect(response.headers['post'], 'world');
        expect(context.request.headers['pre'], 'hello');
        expect(context.request.headers['post'], 'world');
      },
    );

    requestTest(
      'modifications can be overridden',
      TestRoute(
        interceptors: [_ModifyingInterceptor()],
        handler: (context) async {
          context.data.remove<String>();

          context.response.headers.remove('pre');
          context.request.headers.remove('pre');

          context.response.body = 'Goodbye, World!';

          context.response.headers['goodbye'] = 'world';
          context.request.headers['goodbye'] = 'world';

          expect(context.data.contains('Hello, World!'), isFalse);
          expect(context.data.has<String>(), isFalse);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Goodbye, World!');

        expect(response.headers['pre'], isNull);
        expect(context.request.headers['pre'], isNull);

        expect(response.headers['post'], 'world');
        expect(context.request.headers['post'], 'world');
      },
    );
  });
}

class _SuccessInterceptor implements Interceptor {
  bool postWasCalled = false;
  bool preWasCalled = false;

  @override
  Future<void> post(Context context) async {
    postWasCalled = true;
  }

  @override
  Future<void> pre(Context context) async {
    preWasCalled = true;
  }
}

class _OrderedInterceptor implements Interceptor {
  _OrderedInterceptor(this.index, this.controller);

  final int index;
  final StreamController<String> controller;

  @override
  Future<void> post(Context context) async {
    controller.add('post-$index');
  }

  @override
  Future<void> pre(Context context) async {
    controller.add('pre-$index');
  }
}

class _ModifyingInterceptor implements Interceptor {
  @override
  Future<void> post(Context context) async {
    context.response.body = 'Goodbye, World!';
    context.response.headers['post'] = 'world';
    context.request.headers['post'] = 'world';
  }

  @override
  Future<void> pre(Context context) async {
    context.data.add('Hello, World!');
    context.response.headers['pre'] = 'hello';
    context.request.headers['pre'] = 'hello';
  }
}
