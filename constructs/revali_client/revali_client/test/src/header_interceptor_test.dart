import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

HttpRequest requestWith([Map<String, String>? headers]) => HttpRequest(
  method: 'GET',
  url: Uri.parse('http://example.test/thing'),
  headers: headers,
);

void main() {
  group('HeaderInterceptor', () {
    test('adds the headers the callback returns', () {
      final request = requestWith();

      const HeaderInterceptor(_static).onRequest(request);

      expect(request.headers, {'X-Request-Id': 'abc'});
    });

    test('adds nothing when the callback returns nothing', () {
      final request = requestWith();

      HeaderInterceptor(() => const {}).onRequest(request);

      expect(request.headers, isEmpty);
    });

    test('never clobbers a header the call site set', () {
      final request = requestWith({'X-Request-Id': 'explicit'});

      const HeaderInterceptor(_static).onRequest(request);

      // An ambient default losing to an argument is what a caller expects;
      // the reverse is very hard to debug.
      expect(request.headers['X-Request-Id'], 'explicit');
    });

    test('is called per request, not once per client', () {
      var calls = 0;
      final interceptor = HeaderInterceptor(() => {'n': '${++calls}'});

      final first = requestWith();
      final second = requestWith();

      interceptor
        ..onRequest(first)
        ..onRequest(second);

      // The motivating case is correlation, where the value differs for every
      // request — a value captured once would tag them all identically.
      expect(first.headers['n'], '1');
      expect(second.headers['n'], '2');
    });

    test('leaves the response alone', () {
      final response = HttpResponse(
        request: requestWith(),
        statusCode: 200,
        headers: const {},
        stream: const Stream.empty(),
        persistentConnection: false,
        reasonPhrase: 'OK',
        contentLength: 0,
      );

      expect(
        () => const HeaderInterceptor(_static).onResponse(response),
        returnsNormally,
      );
    });
  });
}

Map<String, String> _static() => const {'X-Request-Id': 'abc'};
