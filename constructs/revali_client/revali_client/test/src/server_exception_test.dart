import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

ServerException from(Object? body) => ServerException.fromBody(
  message: 'Not Found',
  statusCode: 404,
  body: body == null ? null : jsonEncode(body),
);

void main() {
  group('ServerException.fromBody', () {
    test('reads the error envelope', () {
      final exception = from({
        'error': {
          'code': 'user_not_found',
          'message': 'No user with that id',
          'details': {'id': 7},
        },
      });

      expect(exception.code, 'user_not_found');
      expect(exception.reason, 'No user with that id');
      expect(exception.details, {'id': 7});
      expect(exception.isStructured, isTrue);
    });

    test('keeps the status and reason phrase alongside it', () {
      final exception = from({
        'error': {'code': 'nope', 'message': 'no'},
      });

      expect(exception.statusCode, 404);
      expect(exception.message, 'Not Found');
    });

    test('omits details when the peer sent none', () {
      final exception = from({
        'error': {'code': 'nope', 'message': 'no'},
      });

      expect(exception.details, isNull);
    });

    group('a peer that does not send the envelope', () {
      test('is not structured, but still an exception', () {
        final exception = ServerException.fromBody(
          message: 'Not Found',
          statusCode: 404,
          body: 'Not Found',
        );

        // The framework's own plain-text defaults land here, which is why
        // nothing about them had to change.
        expect(exception.isStructured, isFalse);
        expect(exception.code, isNull);
        expect(exception.body, 'Not Found');
      });

      test('survives a body that is not JSON at all', () {
        final exception = ServerException.fromBody(
          message: 'Bad Gateway',
          statusCode: 502,
          body: '<html>nginx</html>',
        );

        // An intermediary's HTML error page must surface as the HTTP failure
        // it is, not as a FormatException from the client.
        expect(exception.statusCode, 502);
        expect(exception.code, isNull);
        expect(exception.body, '<html>nginx</html>');
      });

      test('survives JSON that is not an envelope', () {
        final exception = from({'message': 'nope'});

        expect(exception.code, isNull);
        expect(exception.body, isNotNull);
      });

      test('survives an error field of the wrong shape', () {
        final exception = from({'error': 'a string, not an object'});

        expect(exception.code, isNull);
      });

      test('survives a code of the wrong type', () {
        final exception = from({
          'error': {'code': 42, 'message': 'no'},
        });

        // Ignored rather than stringified: a caller branching on `code` should
        // see "no code" rather than "42".
        expect(exception.code, isNull);
        expect(exception.reason, 'no');
      });

      test('handles an empty and an absent body', () {
        expect(
          ServerException.fromBody(
            message: 'x',
            statusCode: 500,
            body: '',
          ).code,
          isNull,
        );
        expect(from(null).code, isNull);
      });
    });

    test('toString surfaces the code and reason', () {
      final text = from({
        'error': {'code': 'user_not_found', 'message': 'No user'},
      }).toString();

      expect(text, contains('user_not_found'));
      expect(text, contains('No user'));
    });
  });
}
