import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Observer, () {
    test('runs gracefully', () async {
      final observer = _SuccessObserver();

      await testRequest(
        TestRoute(
          observers: [observer],
        ),
        verifyResponse: (response, context) {
          expect(observer.beforeWasCalled, isTrue);
          expect(observer.afterWasCalled, isTrue);
        },
      );
    });
  });
}

class _SuccessObserver implements Observer {
  bool beforeWasCalled = false;
  bool afterWasCalled = false;

  @override
  Future<void> see(
    Request request,
    Future<Response> response,
  ) async {
    beforeWasCalled = true;

    await response;

    afterWasCalled = true;
  }
}
