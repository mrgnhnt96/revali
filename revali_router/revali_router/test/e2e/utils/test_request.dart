import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

Future<void> testRequest(
  Router router, {
  required String method,
  required String path,
  required FutureOr<void> Function(HttpResponse response, HttpHeaders headers)
      verifyResponse,
  FutureOr<void> Function(Stream<List<int>>? body)? verifyBody,
}) async {
  final request = _MockHttpRequest();
  final response = request.stub(
    method: method,
    path: path,
  );
  final server = _MockServer();

  final controller = await server.stub();
  controller.add(request);

  final completer = Completer<void>();
  when(server.close).thenAnswer((_) async {
    completer.complete();
  });

  handleRequests(
    server,
    router.handle,
    router.responseHandler,
  ).then((_) => completer.complete()).ignore();
  await controller.close();
  await completer.future;

  if (verifyBody != null) {
    Stream<List<int>>? responseStream;

    verify(
      () => response.addStream(
        any(
          that: isA<Stream<List<int>>>().having(
            (stream) {
              responseStream = stream;

              return stream;
            },
            'stream',
            isA<Stream<List<int>>>(),
          ),
        ),
      ),
    ).called(1);

    await verifyBody(responseStream);
  }

  await verifyResponse(response, response.headers);
}

class _MockHttpRequest extends Mock implements HttpRequest {}

class _MockHttpResponse extends Mock implements HttpResponse {}

class _MockServer extends Mock implements HttpServer {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

extension _HttpRequestX on HttpRequest {
  HttpResponse stub({
    String method = 'GET',
    String path = '',
  }) {
    final mockResponse = _MockHttpResponse()..stub();
    final mockHeaders = _MockHttpHeaders();

    final instance = this;
    when(() => instance.method).thenReturn(method);
    when(() => instance.uri)
        .thenReturn(Uri.parse('http://localhost:8080/$path'));
    when(() => instance.response).thenReturn(mockResponse);
    when(() => instance.headers).thenReturn(mockHeaders);
    when(() => instance.protocolVersion).thenReturn('1.1');

    return mockResponse;
  }
}

extension _HttpResponseX on HttpResponse {
  void stub() {
    final mockHeaders = _MockHttpHeaders();

    final instance = this;
    when(instance.close).thenAnswer((_) async {});
    when(instance.flush).thenAnswer((_) async {});
    when(() => instance.write(any())).thenAnswer((_) async {});

    when(() => instance.headers).thenReturn(mockHeaders);

    when(() => instance.addStream(any())).thenAnswer((_) async {});
  }
}

extension _HttpServerX on HttpServer {
  Future<StreamController<HttpRequest>> stub() async {
    final instance = this;

    final controller = StreamController<HttpRequest>();

    when(
      () => instance.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      ),
    ).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(HttpRequest);
      final onError = invocation.namedArguments[#onError] as Function?;
      final onDone = invocation.namedArguments[#onDone] as void Function()?;

      return controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
      );
    });

    return controller;
  }
}
