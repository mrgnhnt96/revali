import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router/src/request/underlying_request_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

class _MockHttpConnectionInfo extends Mock implements HttpConnectionInfo {}

void main() {
  group('UnderlyingRequestImpl', () {
    test('ip returns remote address from connection info', () {
      final httpRequest = _MockHttpRequest();
      final connectionInfo = _MockHttpConnectionInfo();

      when(() => httpRequest.connectionInfo).thenReturn(connectionInfo);
      when(() => connectionInfo.remoteAddress)
          .thenReturn(InternetAddress('203.0.113.42'));
      when(() => httpRequest.headers).thenReturn(_MockHttpHeaders());
      when(() => httpRequest.uri).thenReturn(Uri.parse('http://localhost/'));
      when(() => httpRequest.method).thenReturn('GET');
      when(() => httpRequest.protocolVersion).thenReturn('1.1');

      final request = UnderlyingRequestImpl.fromRequest(httpRequest);

      expect(request.ip, '203.0.113.42');
    });

    test('ip is null when connection info is unavailable', () {
      final httpRequest = _MockHttpRequest();

      when(() => httpRequest.connectionInfo).thenReturn(null);
      when(() => httpRequest.headers).thenReturn(_MockHttpHeaders());
      when(() => httpRequest.uri).thenReturn(Uri.parse('http://localhost/'));
      when(() => httpRequest.method).thenReturn('GET');
      when(() => httpRequest.protocolVersion).thenReturn('1.1');

      final request = UnderlyingRequestImpl.fromRequest(httpRequest);

      expect(request.ip, isNull);
    });

    test('ip uses rightmost X-Forwarded-For when trusted proxy is configured',
        () {
      final httpRequest = _MockHttpRequest();
      final connectionInfo = _MockHttpConnectionInfo();

      when(() => httpRequest.connectionInfo).thenReturn(connectionInfo);
      when(() => connectionInfo.remoteAddress)
          .thenReturn(InternetAddress('10.0.0.1'));
      when(() => httpRequest.uri).thenReturn(Uri.parse('http://localhost/'));
      when(() => httpRequest.method).thenReturn('GET');
      when(() => httpRequest.protocolVersion).thenReturn('1.1');

      final request = UnderlyingRequestImpl(
        body: PayloadImpl(httpRequest, encoding: utf8),
        headers: HeadersImpl({
          'x-forwarded-for': ['203.0.113.1, 198.51.100.178'],
        }),
        uri: Uri.parse('http://localhost/'),
        method: 'GET',
        request: httpRequest,
        protocolVersion: '1.1',
        trustedProxy: const TrustedProxy(headers: ['X-Forwarded-For']),
      );

      expect(request.ip, '198.51.100.178');
    });
  });
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}
