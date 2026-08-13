part of '../router.dart';

typedef DebugErrorResponse = Response Function(
  Response response, {
  required Object error,
  required StackTrace stackTrace,
});

mixin HelperMixin {
  BaseRoute get route;
  LifecycleComponents get globalComponents;
  FullRequest get request;
  Response get response;
  CloseWebSocket get close;
  Data get data;
  MetaScope get meta;
  Reflect get reflectHandler;
  DebugErrorResponse get debugErrorResponse;
  DefaultResponses get defaultResponses;
  bool get debugResponses;
  List<RequestListener> get observers;
  Future<Response> get observerResponseFuture;

  AsyncWebSocketSender<dynamic> get asyncSender;
  set webSocketSender(void Function(dynamic data) sender);

  set webSocketRequest(WebSocketRequest request);

  ContextMixin get context;
  RunMixin get run;

  /// Cached per-request so we don't rebuild spreads on every lifecycle stage.
  late final List<Middleware> middlewares = [
    ...globalComponents.middlewares,
    ...route.allMiddlewares,
  ];

  late final List<RequestWrapper> requestWrappers = [
    ...globalComponents.requestWrappers,
    ...route.allRequestWrappers,
  ];

  late final List<Interceptor> interceptors = [
    ...globalComponents.interceptors,
    ...route.allInterceptors,
  ];

  late final List<Guard> guards = [
    ...globalComponents.guards,
    ...route.allGuards,
  ];

  // ignore: strict_raw_type
  late final List<ExceptionCatcher> catchers = [
    ...route.allCatchers,
    ...globalComponents.catchers,
  ]..sort((a, b) {
      if (a is DefaultExceptionCatcher) {
        return 1;
      }

      if (b is DefaultExceptionCatcher) {
        return -1;
      }

      return 0;
    });

  Set<String> get allowedOrigins => {
        if (route.allowedOrigins?.inherit case final inherit? when inherit)
          ...?globalComponents.allowedOrigins?.origins,
        ...route.allAllowedOrigins,
      };

  Set<String> get preventedHeaders => {
        if (route.preventedHeaders?.inherit case final inherit? when inherit)
          ...?globalComponents.preventedHeaders?.headers,
        ...route.allPreventedHeaders,
      };

  Set<String> get expectedHeaders => {
        ...?globalComponents.expectedHeaders?.headers,
        ...route.allExpectedHeaders,
      };
}
