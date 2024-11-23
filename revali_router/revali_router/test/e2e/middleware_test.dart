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
          final headers = response.joinedHeaders.values;

          expect(headers, hasLength(4));

          expect(
            headers[HttpHeaders.accessControlAllowMethodsHeader]?.single,
            'OPTIONS, GET, HEAD',
          );
          expect(
            headers[HttpHeaders.allowHeader]?.single,
            'OPTIONS, GET, HEAD',
          );
          expect(
            headers[HttpHeaders.accessControlAllowCredentialsHeader]?.single,
            'true',
          );
          expect(
            headers[HttpHeaders.accessControlAllowOriginHeader]?.single,
            '*',
          );
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
