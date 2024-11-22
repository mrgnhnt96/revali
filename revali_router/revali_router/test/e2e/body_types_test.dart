import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(String, () {
    test('handles body gracefully', () async {
      final router = Router(
        routes: [
          Route(
            '',
            method: 'GET',
            handler: (context) async {
              context.response.statusCode = HttpStatus.ok;
              context.response.body = 'Hello, World!';
            },
          ),
        ],
      );

      await testRequest(
        router,
        method: 'GET',
        path: '',
        verifyResponse: (response, context) {
          expect(response.statusCode, HttpStatus.ok);
          final body = response.body;

          expect(body, isNotNull);
          expect(body, isA<MutableBody>());
          if (body is! MutableBody) {
            return;
          }

          expect(body.data, 'Hello, World!');
          expect(body.contentLength, 'Hello, World!'.length);
          expect(body.mimeType, 'text/plain');
          expect(body.isNull, isFalse);
          expect(body.encoding, utf8);
          expect(body.read(), emits(utf8.encode('Hello, World!')));
        },
      );
    });
  });
}
