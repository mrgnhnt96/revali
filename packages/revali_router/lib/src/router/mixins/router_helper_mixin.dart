part of '../router.dart';

typedef _DebugErrorResponse = ReadOnlyResponse Function(
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
  _DebugErrorResponse get debugErrorResponse;
  DefaultResponses get defaultResponses;

  bool get debugResponses;

  List<Middleware> get middlewares {
    return [
      ...globalModifiers.middlewares,
      ...route.middlewares,
    ];
  }

  List<Interceptor> get interceptors {
    return [
      ...globalModifiers.interceptors,
      ...route.interceptors,
    ];
  }

  List<Guard> get guards {
    return [
      ...globalModifiers.guards,
      ...route.guards,
    ];
  }

  List<ExceptionCatcher> get catchers {
    return [
      ...route.catchers,
      ...globalModifiers.catchers,
    ];
  }

  _RunInterceptors get runInterceptors => _RunInterceptors(this);
  _RunGuards get runGuards => _RunGuards(this);
  _RunMiddlewares get runMiddlewares => _RunMiddlewares(this);
  _RunCatchers get runCatchers => _RunCatchers(this);
  _RunOptions get runOptions => _RunOptions(this);
  _RunRedirect get runRedirect => _RunRedirect(this);
  _RunOriginCheck get runOriginCheck => _RunOriginCheck(this);
  _Execute get execute => _Execute(this);

  Future<WebSocketResponse> handleWebSocket(
      FutureOr<WebSocketHandler> handler) async {
    final route = this.route;
    if (route is! WebSocketRoute) {
      throw StateError('Route is not a WebSocketRoute');
    }

    return _HandleWebSocket(
      handler: await handler,
      mode: route.mode,
      ping: route.ping,
      helper: this,
    ).handle();
  }

  EndpointContext get endpointContext => EndpointContextImpl(
        meta: directMeta,
        reflect: reflectHandler,
        request: request,
        data: dataHandler,
        response: response,
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
