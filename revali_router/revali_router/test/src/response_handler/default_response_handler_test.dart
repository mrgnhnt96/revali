import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/response_handler/default_response_handler.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockHttpResponse extends Mock implements HttpResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

void main() {
  group(DefaultResponseHandler, () {
    late _MockRequestContext context;
    late _MockHttpResponse http;
    late _MockHttpHeaders httpHeaders;
    late Map<String, String> written;
    late Map<String, List<String>> addedValues;

    setUp(() {
      context = _MockRequestContext();
      http = _MockHttpResponse();
      httpHeaders = _MockHttpHeaders();
      written = {};
      addedValues = {};

      when(() => context.method).thenReturn('GET');
      when(context.close).thenAnswer((_) async {});

      when(() => http.headers).thenReturn(httpHeaders);
      when(() => http.statusCode).thenReturn(200);
      when(() => http.statusCode = any()).thenReturn(200);
      when(http.flush).thenAnswer((_) async {});
      when(http.close).thenAnswer((_) async {});
      // Non-null connectionInfo so the handler attempts to write the body.
      when(() => http.connectionInfo).thenReturn(null);
      when(
        () => httpHeaders.set(
          any(),
          any(),
          preserveHeaderCase: any(named: 'preserveHeaderCase'),
        ),
      ).thenAnswer((invocation) {
        final name = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1];
        written[name.toLowerCase()] = value.toString();
      });
      when(
        () => httpHeaders.add(
          any(),
          any(),
          preserveHeaderCase: any(named: 'preserveHeaderCase'),
        ),
      ).thenAnswer((invocation) {
        final name = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1];
        addedValues.putIfAbsent(name.toLowerCase(), () => []).add('$value');
      });
    });

    test('writes an HTTP-date Date header', () async {
      await const DefaultResponseHandler().handle(
        SimpleResponse(200, body: 'ok'),
        context,
        http,
      );

      final raw = written[HttpHeaders.dateHeader];
      expect(raw, isNotNull);
      expect(() => HttpDate.parse(raw!), returnsNormally);
    });

    test('reuses the cached Date string within the same second', () async {
      const handler = DefaultResponseHandler();

      await handler.handle(SimpleResponse(200, body: 'a'), context, http);
      final first = written[HttpHeaders.dateHeader];

      written.clear();
      await handler.handle(SimpleResponse(200, body: 'b'), context, http);
      final second = written[HttpHeaders.dateHeader];

      expect(first, isNotNull);
      expect(second, first);
    });

    test('writes one Set-Cookie header per cookie via add, not a joined set',
        () async {
      final response = SimpleResponse(200, body: 'ok');
      response.headers.setCookies
        ..['a'] = '1'
        ..['b'] = '2';

      await const DefaultResponseHandler().handle(response, context, http);

      final setCookieValues = addedValues[HttpHeaders.setCookieHeader];
      expect(setCookieValues, isNotNull);
      expect(setCookieValues, hasLength(2));
      expect(setCookieValues!.any((v) => v.startsWith('a=1;')), isTrue);
      expect(setCookieValues.any((v) => v.startsWith('b=2;')), isTrue);

      // Set-Cookie must never go through `.set()` with joined values.
      expect(written.containsKey(HttpHeaders.setCookieHeader), isFalse);
    });
  });
}
