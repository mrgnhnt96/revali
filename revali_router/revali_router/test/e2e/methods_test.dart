// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';

import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(Method, () {
    void verifyResponse(
      Iterable<String> allowMethods,
      Response response,
      RequestContext context,
    ) {
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, isA<Body>());
      expect(response.body.isNull, isTrue);

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
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'GET',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'HEAD', 'GET'], response, context),
      );
    });

    group(Post, () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'POST',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'POST'], response, context),
      );
    });

    group(Delete, () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'DELETE',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'DELETE'], response, context),
      );
    });

    group(Patch, () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'PATCH',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'PATCH'], response, context),
      );
    });

    group(Put, () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'PUT',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'PUT'], response, context),
      );
    });

    group(Head, () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'HEAD',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS', 'HEAD'], response, context),
      );
    });

    group('Options', () {
      requestTest(
        'handles gracefully',
        TestRoute(
          method: 'OPTIONS',
        ),
        verifyResponse: (response, context) =>
            verifyResponse(['OPTIONS'], response, context),
      );
    });
  });
}
