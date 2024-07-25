part of '../router.dart';

typedef DebugErrorResponse = ReadOnlyResponse Function(
  ReadOnlyResponse response, {
  required Object error,
  required StackTrace stackTrace,
});

mixin RouterHelperMixin {
  BaseRoute get route;
  RouteModifiers get globalModifiers;
  MutableRequest get request;
  MutableResponse get response;
  DataHandler get dataHandler;
  MetaHandler get directMeta;
  MetaHandler get inheritedMeta;
  ReflectHandler get reflectHandler;
  DebugErrorResponse get debugErrorResponse;
  DefaultResponses get defaultResponses;
  bool get debugResponses;

  ContextHelperMixin get context;

  List<Middleware> get middlewares {
    return [
      ...globalModifiers.middlewares,
      ...route.allMiddlewares,
    ];
  }

  List<Interceptor> get interceptors {
    return [
      ...globalModifiers.interceptors,
      ...route.allInterceptors,
    ];
  }

  List<Guard> get guards {
    return [
      ...globalModifiers.guards,
      ...route.allGuards,
    ];
  }

  List<ExceptionCatcher> get catchers {
    return [
      ...route.allCatchers,
      ...globalModifiers.catchers,
    ];
  }

  RunInterceptors get runInterceptors => RunInterceptors(this);
  RunGuards get runGuards => RunGuards(this);
  RunMiddlewares get runMiddlewares => RunMiddlewares(this);
  RunCatchers get runCatchers => RunCatchers(this);
  RunOptions get runOptions => RunOptions(this);
  RunRedirect get runRedirect => RunRedirect(this);
  RunOriginCheck get runOriginCheck => RunOriginCheck(this);
  Execute get execute => Execute(this, context);

  HandleWebSocket handleWebSocket(dynamic handler) => HandleWebSocket(
        handler: handler,
        mode: (route as WebSocketRoute).mode,
        ping: (route as WebSocketRoute).ping,
        helper: this,
      );

  Set<String> get allowedOrigins => {
        if (route.allowedOrigins?.inherit case final inherit? when inherit)
          ...?globalModifiers.allowedOrigins?.origins,
        ...route.allAllowedOrigins,
      };

  Set<String> get allowedHeaders => {
        if (route.allowedHeaders?.inherit case final inherit? when inherit)
          ...?globalModifiers.allowedHeaders?.headers,
        ...route.allAllowedHeaders,
      };
}
