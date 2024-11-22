import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Middleware, () {
    test('runs gracefully', () async {
      final router = Router(
        routes: [
          Route(
            '',
            middlewares: const [_SuccessMiddleware()],
            method: 'GET',
            handler: (context) async {},
          ),
        ],
      );

      await testRequest(
        router,
        method: 'GET',
        path: '',
        verifyResponse: (response, context) {
          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, isA<MutableBody>());
          expect(response.body?.isNull, isTrue);
          expect(response.headers.values, isEmpty);
        },
      );
    });
  });
}

class _SuccessMiddleware implements Middleware {
  const _SuccessMiddleware();
  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  ) async {
    return action.next();
  }
}
