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

  /// Formats a failure the app never spoke for; substitutes a 5xx in release.
  DebugErrorResponse get debugErrorResponse;

  /// Formats a failure the app authored; delivers a 5xx as written.
  DebugErrorResponse get authoredErrorResponse;
  DefaultResponses get defaultResponses;
  bool get debugResponses;
  List<Observer> get observers;
  Future<Response> get observerResponseFuture;
  Future<RequestSummary> get observerSummaryFuture;

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

  /// Whether the app-level value reaches [route]: true unless the endpoint
  /// or one of its parents opted out with `noInherit` (or `.all()`).
  bool _inheritsFromApp(bool? Function(BaseRoute) inheritOf) {
    for (BaseRoute? current = route;
        current != null;
        current = current.parent) {
      if (inheritOf(current) == false) {
        return false;
      }
    }

    return true;
  }

  Set<String> get allowedOrigins => {
        if (_inheritsFromApp((r) => r.allowedOrigins?.inherit))
          ...?globalComponents.allowedOrigins?.origins,
        ...route.allAllowedOrigins,
      };

  Set<String> get preventedHeaders => {
        if (_inheritsFromApp((r) => r.preventedHeaders?.inherit))
          ...?globalComponents.preventedHeaders?.headers,
        ...route.allPreventedHeaders,
      };

  Set<String> get expectedHeaders => {
        ...?globalComponents.expectedHeaders?.headers,
        ...route.allExpectedHeaders,
      };
}
