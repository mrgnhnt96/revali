import 'dart:async';

import 'package:revali_router_core/guard/guard.dart';
import 'package:revali_router_core/guard/guard_context.dart';
import 'package:revali_router_core/guard/guard_result.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group('Guard', () {
    test('runs gracefully', () async {
      final guard = _SuccessGuard();

      await testRequest(
        TestRoute(
          guards: [guard],
        ),
        verifyResponse: (response, context) {
          expect(guard.wasCalled, isTrue);
        },
      );
    });

    test('runs in order', () async {
      final controller = StreamController<int>();

      await testRequest(
        TestRoute(
          guards: List.generate(
            5,
            (index) => _OrderedGuard(index, controller),
          ),
        ),
        verifyResponse: (response, context) {
          expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4]));
        },
      );
    });

    requestTest(
      'modifications persist throughout the guard chain',
      TestRoute(
        guards: [_ModifyingGuard()],
        handler: (context) async {
          expect(context.data.contains('Hello, Guard!'), isTrue);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Hello, Guard!');
        expect(response.headers['guard'], 'active');
      },
    );

    requestTest(
      'modifications can be overridden by subsequent guards',
      TestRoute(
        guards: [_ModifyingGuard()],
        handler: (context) async {
          context.data.remove<String>();

          context.response.headers.remove('guard');
          context.request.headers.remove('guard');

          context.response.body = 'Overridden by handler';

          expect(context.data.contains('Hello, Guard!'), isFalse);
        },
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Overridden by handler');
        expect(response.headers['guard'], isNull);
      },
    );

    requestTest(
      'returning a response halts execution and overrides response',
      TestRoute(
        guards: const [_HaltingGuard.overrideResponse()],
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Guard Overridden');
        expect(response.headers['overridden'], 'true');
        expect(response.statusCode, -1);
      },
    );

    requestTest(
      'returning a response halts execution and inherits existing response',
      TestRoute(
        guards: const [_HaltingGuard()],
      ),
      verifyResponse: (response, context) {
        expect(response.body?.data, 'Guard Not overridden');
        expect(response.headers['overridden'], 'false');
        expect(response.statusCode, 403);
      },
    );

    test('does not execute subsequent guards if halted', () async {
      final successGuard = _SuccessGuard();

      await testRequest(
        TestRoute(
          guards: [
            const _HaltingGuard(),
            successGuard,
          ],
        ),
        verifyResponse: (response, context) {
          expect(successGuard.wasCalled, isFalse);
        },
      );
    });
  });
}

class _SuccessGuard implements Guard {
  _SuccessGuard();

  bool wasCalled = false;

  @override
  Future<GuardResult> protect(GuardContext context) async {
    wasCalled = true;
    return const GuardResult.pass();
  }
}

class _OrderedGuard implements Guard {
  _OrderedGuard(this.index, this.controller);

  final int index;
  final StreamController<int> controller;

  @override
  Future<GuardResult> protect(GuardContext context) async {
    controller.add(index);
    return const GuardResult.pass();
  }
}

class _ModifyingGuard implements Guard {
  _ModifyingGuard();

  @override
  Future<GuardResult> protect(GuardContext context) async {
    context.data.add('Hello, Guard!');
    context.response.body = 'Hello, Guard!';
    context.response.headers['guard'] = 'active';

    return const GuardResult.pass();
  }
}

class _HaltingGuard implements Guard {
  const _HaltingGuard() : overrideResponse = false;
  const _HaltingGuard.overrideResponse() : overrideResponse = true;

  final bool overrideResponse;

  @override
  Future<GuardResult> protect(GuardContext context) async {
    if (overrideResponse) {
      return const GuardResult.block(
        body: 'Guard Overridden',
        headers: {'overridden': 'true'},
        statusCode: -1,
      );
    }

    context.response.body = 'Guard Not overridden';
    context.response.headers['overridden'] = 'false';
    return const GuardResult.block();
  }
}
