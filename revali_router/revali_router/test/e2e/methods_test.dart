import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Method, () {
    void verifyResponse(
      String method,
      ReadOnlyResponse response,
      RequestContext context,
    ) {
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, isA<MutableBody>());
      expect(response.body?.isNull, isTrue);

      final headers = response.joinedHeaders;
      expect(headers, hasLength(4));

      final head = switch (method) {
        'GET' => ', HEAD',
        _ => '',
      };

      expect(
        headers[HttpHeaders.accessControlAllowMethodsHeader],
        'OPTIONS, $method$head',
      );
      expect(
        headers[HttpHeaders.allowHeader],
        'OPTIONS, $method$head',
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
              verifyResponse('GET', response, context),
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
              verifyResponse('POST', response, context),
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
              verifyResponse('DELETE', response, context),
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
              verifyResponse('PATCH', response, context),
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
              verifyResponse('PUT', response, context),
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
              verifyResponse('HEAD', response, context),
        );
      });
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
        verifyResponse: (response, context) {
          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, isA<MutableBody>());
          expect(response.body?.isNull, isTrue);

          final headers = response.joinedHeaders;
          expect(headers, hasLength(4));

          expect(
            headers[HttpHeaders.accessControlAllowMethodsHeader],
            'OPTIONS',
          );
          expect(
            headers[HttpHeaders.allowHeader],
            'OPTIONS',
          );
          expect(
            headers[HttpHeaders.accessControlAllowCredentialsHeader],
            'true',
          );
          expect(
            headers[HttpHeaders.accessControlAllowOriginHeader],
            '*',
          );
        },
      );
    });
  });
}
