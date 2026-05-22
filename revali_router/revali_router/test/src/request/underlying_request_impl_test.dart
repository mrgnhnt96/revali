import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/src/request/underlying_request_impl.dart';
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
  });
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}
