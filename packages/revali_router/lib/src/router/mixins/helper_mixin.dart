part of '../router.dart';

typedef DebugErrorResponse = ReadOnlyResponse Function(
  ReadOnlyResponse response, {
  required Object error,
  required StackTrace stackTrace,
});

mixin HelperMixin {
  BaseRoute get route;
  LifecycleComponents get globalComponents;
  MutableRequest get request;
  MutableResponse get response;
  DataHandler get dataHandler;
  MetaHandler get directMeta;
  MetaHandler get inheritedMeta;
  ReflectHandler get reflectHandler;
  DebugErrorResponse get debugErrorResponse;
  DefaultResponses get defaultResponses;
  bool get debugResponses;

  ContextMixin get context;
  RunMixin get run;

  List<Middleware> get middlewares {
    return [
      ...globalComponents.middlewares,
      ...route.allMiddlewares,
    ];
  }

  List<Interceptor> get interceptors {
    return [
      ...globalComponents.interceptors,
      ...route.allInterceptors,
    ];
  }

  List<Guard> get guards {
    return [
      ...globalComponents.guards,
      ...route.allGuards,
    ];
  }

  List<ExceptionCatcher> get catchers {
    return [
      ...route.allCatchers,
      ...globalComponents.catchers,
    ];
  }

  Set<String> get allowedOrigins => {
        if (route.allowedOrigins?.inherit case final inherit? when inherit)
          ...?globalComponents.allowedOrigins?.origins,
        ...route.allAllowedOrigins,
      };

  Set<String> get allowedHeaders => {
        if (route.allowedHeaders?.inherit case final inherit? when inherit)
          ...?globalComponents.allowedHeaders?.headers,
        ...route.allAllowedHeaders,
      };
}
