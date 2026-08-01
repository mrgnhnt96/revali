import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

void main() {
  group('MissingArgumentException', () {
    test('toString includes expected and actual when set', () {
      const e = MissingArgumentException(
        key: 'shopId',
        location: '@query',
        expectedType: 'String',
        actualType: 'null',
      );

      expect(
        e.toString(),
        'MissingArgumentException: key: shopId, location: @query, '
        'expected: String, actual: null',
      );
    });

    test('unhandled MissingArgumentException maps to 400 badRequest', () async {
      final router = Router(
        debug: true,
        routes: [
          Route(
            'ping',
            method: 'GET',
            handler: (_) async {
              throw const MissingArgumentException(
                key: 'id',
                location: '@query',
                expectedType: 'String',
                actualType: 'null',
              );
            },
          ),
        ],
      );

      final context = _MockRequest()..stub('ping');
      final response = await router.handle(context);

      expect(response.statusCode, HttpStatus.badRequest);
      expect(response.body.data.toString(), contains('Bad Request'));
      expect(
        response.body.data.toString(),
        contains('MissingArgumentException'),
      );
    });
  });
}

class _MockRequest extends Mock implements RequestContext {}

class _MockUnderlyingRequest extends Mock implements UnderlyingRequest {}

extension on RequestContext {
  void stub(String path, {String method = 'GET'}) {
    final uri = Uri.parse(path);
    when(() => segments).thenReturn(uri.pathSegments);
    when(() => this.method).thenReturn(method);
    when(() => queryParameters).thenReturn(uri.queryParameters);
    when(() => queryParametersAll).thenReturn(uri.queryParametersAll);
    when(() => this.uri).thenReturn(uri);
    when(() => headers).thenReturn(HeadersImpl({}));

    final request = _MockUnderlyingRequest();
    when(() => request.headers).thenReturn(HeadersImpl({}));
    when(() => request.uri).thenReturn(uri);
    when(() => request.method).thenReturn(method);
    when(() => this.request).thenReturn(request);
  }
}
