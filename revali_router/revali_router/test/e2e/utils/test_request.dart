import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:revali_router/revali_router.dart';

typedef ResponseCompleter
    = Completer<(ReadOnlyResponse response, RequestContext context)>;

Future<void> testRequest(
  Router router, {
  required String method,
  required String path,
  required FutureOr<void> Function(ReadOnlyResponse, RequestContext)
      verifyResponse,
}) async {
  final responseCompleter = ResponseCompleter();

  final request = _MockHttpRequest()..stub(method: method, path: path);
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
    (_) async => TestResponseHandler(responseCompleter),
  ).then((_) => completer.complete()).ignore();
  await controller.close();
  await completer.future;

  final (response, context) = await responseCompleter.future;

  await verifyResponse(response, context);
}

class TestResponseHandler implements ResponseHandler {
  const TestResponseHandler(this.completer);

  final ResponseCompleter completer;

  @override
  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    completer.complete((response, context));
  }
}

class _MockHttpRequest extends Mock implements HttpRequest {}

class _FakeHttpResponse extends Fake implements HttpResponse {}

class _MockServer extends Mock implements HttpServer {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

extension _HttpRequestX on HttpRequest {
  HttpResponse stub({
    String method = 'GET',
    String path = '',
  }) {
    final mockResponse = _FakeHttpResponse();
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
