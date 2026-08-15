// ignore_for_file: overridden_fields, unnecessary_await_in_return
// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart' as test;

typedef ResponseCompleter
    = Completer<(Response response, RequestContext context)>;

@isTest
void requestTest(
  String description,
  TestRoute route, {
  required FutureOr<void> Function(Response, RequestContext) verifyResponse,
  dynamic tags,
}) =>
    test.test(
      description,
      () async {
        await testRequest(route, verifyResponse: verifyResponse);
      },
      tags: tags,
    );

Future<void> testRequest(
  TestRoute route, {
  required FutureOr<void> Function(Response, RequestContext) verifyResponse,
}) async {
  final responseCompleter = ResponseCompleter();

  final request = _MockHttpRequest()
    ..stub(
      method: route.method,
      path: route.requestPath ?? route.path,
      headers: route.headers,
    );
  final server = _MockServer();

  final controller = await server.stub();
  controller.add(request);

  final completer = Completer<void>();
  when(server.close).thenAnswer((_) async {
    completer.complete();
  });

  final router = route.toRouter();

  handleRequests(
    server,
    router.handle,
    (_) async => TestResponseHandler(responseCompleter),
    () {},
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
    Response response,
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
    Map<String, String> headers = const {},
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
    when(() => mockHeaders.forEach(any())).thenAnswer((invocation) {
      final action = invocation.positionalArguments[0];
      for (final MapEntry(:key, :value) in headers.entries) {
        action(key, [value]);
      }
    });

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

// ignore: must_be_immutable
class TestRoute extends Route {
  TestRoute({
    super.handler = _handler,
    this.observers = const [],
    this.path = '',
    this.method = 'GET',
    this.headers = const {},
    this.debug = false,
    this.requestPath,
    super.routes,
    super.middlewares,
    super.requestWrappers,
    super.interceptors,
    super.guards,
    super.catchers,
    super.meta,
    super.redirect,
    super.combine,
    super.allowedOrigins,
    super.preventedHeaders,
    super.ignorePathPattern,
    super.responseHandler,
    super.expectedHeaders,
  }) : super(
          path,
          method: method,
        );

  final List<Observer> observers;
  final Map<String, String> headers;
  final bool debug;

  /// Path to request, when it should differ from the path this route is
  /// registered at -- the only way to drive a request that matches no route.
  final String? requestPath;

  Router toRouter() {
    return Router(
      routes: [this],
      observers: observers,
      debug: debug,
    );
  }

  @override
  final String method;

  @override
  final String path;
}

Future<void> _handler(Context context) async {}
