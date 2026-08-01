import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/response_handler/default_response_handler.dart';
import 'package:revali_router_core/revali_router_core.dart';
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

    setUp(() {
      context = _MockRequestContext();
      http = _MockHttpResponse();
      httpHeaders = _MockHttpHeaders();
      written = {};

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
  });
}
