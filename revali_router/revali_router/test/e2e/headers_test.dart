import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group('Headers', () {
    requestTest(
      'handles $String gracefully',
      TestRoute(
        handler: (context) async {
          context.response.statusCode = HttpStatus.ok;
          context.response.body = 'Hello, World!';
        },
      ),
      verifyResponse: (response, context) {
        expect(response.statusCode, HttpStatus.ok);

        final body = response.body;

        expect(body, isNotNull);
        expect(body, isA<MutableBody>());
        if (body is! MutableBody) {
          return;
        }

        final headers = body.headers(null);

        expect(headers, isNotNull);

        final values = headers.values;
        expect(values, hasLength(2));

        expect(values['content-length']?.single, '13');
        expect(values['content-type']?.single, 'text/plain');
      },
    );
  });
}
