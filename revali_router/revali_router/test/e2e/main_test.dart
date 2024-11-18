import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const Stream<List<int>>.empty());
  });

  group('e2e', () {
    test('runs', () async {
      const content = 'Hello, World!';

      final router = Router(
        routes: [
          Route(
            '',
            method: 'GET',
            handler: (context) async {
              context.response.statusCode = HttpStatus.ok;
              context.response.body = content;
            },
          ),
        ],
      );

      await testRequest(
        router,
        method: 'GET',
        path: '',
        verifyResponse: (response, headers) {
          verify(() => response.statusCode = HttpStatus.ok).called(1);

          verify(
            () => headers.set('content-type', 'text/plain'),
          ).called(1);
          verify(
            () => headers.set('content-length', '${content.length}'),
          ).called(1);
          verify(
            () => headers.date = any(that: isA<DateTime>()),
          ).called(1);
        },
        verifyBody: (stream) async {
          await expectLater(
            stream,
            emitsInOrder([
              utf8.encode(content),
            ]),
          );
        },
      );
    });
  });
}
