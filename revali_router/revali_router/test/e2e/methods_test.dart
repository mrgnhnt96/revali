import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Method, () {
    void verifyResponse(
      Iterable<String> allowMethods,
      ReadOnlyResponse response,
      RequestContext context,
    ) {
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, isA<MutableBody>());
      expect(response.body?.isNull, isTrue);

      final headers = response.joinedHeaders;
      expect(headers, hasLength(4));

      final methods =
          headers[HttpHeaders.accessControlAllowMethodsHeader]?.split(', ');
      expect(
        methods,
        containsAll(allowMethods),
      );

      final allow = headers[HttpHeaders.allowHeader]?.split(', ');
      expect(
        allow,
        containsAll(allowMethods),
      );
      expect(
        headers[HttpHeaders.accessControlAllowCredentialsHeader],
        'true',
      );
      expect(
        headers[HttpHeaders.accessControlAllowOriginHeader],
        '*',
      );
    }

    group(Get, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'GET',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'GET',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'HEAD', 'GET'], response, context),
        );
      });
    });

    group(Post, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'POST',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'POST',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'POST'], response, context),
        );
      });
    });

    group(Delete, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'DELETE',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'DELETE',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'DELETE'], response, context),
        );
      });
    });

    group(Patch, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'PATCH',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'PATCH',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'PATCH'], response, context),
        );
      });
    });

    group(Put, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'PUT',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'PUT',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'PUT'], response, context),
        );
      });
    });

    group(Head, () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'HEAD',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'HEAD',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS', 'HEAD'], response, context),
        );
      });
    });

    group('Options', () {
      test('handles gracefully', () async {
        final router = Router(
          routes: [
            Route(
              '',
              method: 'OPTIONS',
              handler: (context) async {},
            ),
          ],
        );

        await testRequest(
          router,
          method: 'OPTIONS',
          path: '',
          verifyResponse: (response, context) =>
              verifyResponse(['OPTIONS'], response, context),
        );
      });
    });
  });
}
