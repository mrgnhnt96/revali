import 'dart:io';

import 'package:revali_annotations/revali_annotations.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

void main() {
  group(AllowOrigins, () {
    requestTest(
      'allows a request with no Origin header even when origins are '
      'restricted (native/mobile/curl clients never send Origin)',
      TestRoute(
        allowedOrigins: const AllowOrigins({'https://example.com'}),
        handler: (context) async {
          context.response.statusCode = HttpStatus.ok;
        },
      ),
      verifyResponse: (response, context) {
        expect(response.statusCode, HttpStatus.ok);
      },
    );

    requestTest(
      'still rejects a request whose Origin is not in the allowlist',
      TestRoute(
        allowedOrigins: const AllowOrigins({'https://example.com'}),
        headers: const {'origin': 'https://not-allowed.com'},
        handler: (context) async {
          context.response.statusCode = HttpStatus.ok;
        },
      ),
      verifyResponse: (response, context) {
        expect(response.statusCode, HttpStatus.forbidden);
      },
    );

    requestTest(
      'allows and echoes back an Origin that is in the allowlist',
      TestRoute(
        allowedOrigins: const AllowOrigins({'https://example.com'}),
        headers: const {'origin': 'https://example.com'},
        handler: (context) async {
          context.response.statusCode = HttpStatus.ok;
        },
      ),
      verifyResponse: (response, context) {
        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers.values['access-control-allow-origin']?.single,
          'https://example.com',
        );
      },
    );
  });
}
