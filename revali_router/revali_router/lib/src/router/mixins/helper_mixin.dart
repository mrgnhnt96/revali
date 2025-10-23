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

  AsyncWebSocketSender<dynamic> get asyncSender;
  set webSocketSender(void Function(dynamic data) sender);

  set webSocketRequest(WebSocketRequest request);

  ContextMixin get context;
  RunMixin get run;

  Iterable<Middleware> get middlewares {
    return [
      ...globalComponents.middlewares,
      ...route.allMiddlewares,
    ];
  }

  Iterable<Interceptor> get interceptors {
    return [
      ...globalComponents.interceptors,
      ...route.allInterceptors,
    ];
  }

  Iterable<Guard> get guards {
    return [
      ...globalComponents.guards,
      ...route.allGuards,
    ];
  }

  // ignore: strict_raw_type
  Iterable<ExceptionCatcher> get catchers {
    return [
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
  }

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
