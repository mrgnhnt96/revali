import 'package:revali_core/revali_core.dart';
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
  Future<void> see(ObservedRequest observed) async {
    final response = observed.response;

    beforeWasCalled = true;

    await response;

    afterWasCalled = true;
  }
}
