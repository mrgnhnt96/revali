part of 'router.dart';

extension Execute on Router {
  Future<ReadOnlyResponse> execute({
    required BaseRoute route,
    required RouteModifiers globalModifiers,
    required MutableRequest request,
    required MutableResponse response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
    required ReflectHandler reflectHandler,
  }) async {
    final handler = route.handler;
    if (handler == null) {
      return _debugResponse(
        defaultResponses.notFound,
        error: MissingHandlerException(
          method: request.method,
          path: request.segments.join('/'),
        ),
        stackTrace: StackTrace.current,
      );
    }

    if (await runMiddlewares(
      [
        ...globalModifiers.middlewares,
        ...route.allMiddlewares,
      ],
      request: request,
      response: response,
      dataHandler: dataHandler,
    )
        case final response?) {
      return response;
    }

    if (await runGuards(
      [
        ...globalModifiers.guards,
        ...route.allGuards,
      ],
      request: request,
      response: response,
      dataHandler: dataHandler,
      directMeta: directMeta,
      inheritedMeta: inheritedMeta,
      route: route,
    )
        case final response?) {
      return response;
    }

    final interceptors = [
      ...globalModifiers.interceptors,
      ...route.allInterceptors,
    ];
    Future<void> pre() async {
      for (final interceptor in interceptors) {
        await interceptor.pre(
          InterceptorContextImpl(
            meta: InterceptorMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }
    }

    Future<void> post() async {
      for (final interceptor in interceptors) {
        await interceptor.post(
          InterceptorContextImpl(
            meta: InterceptorMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }
    }

    final result = handler.call(
      EndpointContextImpl(
        meta: directMeta,
        reflect: reflectHandler,
        request: request,
        data: dataHandler,
        response: response,
      ),
    );

    if (route is WebSocketRoute) {
      if (result is! FutureOr<WebSocketHandler>) {
        throw InvalidHandlerResultException('${result.runtimeType}', [
          '$WebSocketHandler',
          'Future<$WebSocketHandler>',
        ]);
      }

      return handleWebsocket(
        request: request,
        response: response,
        handler: await result,
        mode: route.mode,
        pre: pre,
        post: post,
      );
    }

    if (result is! Future<void>) {
      throw InvalidHandlerResultException(
        '${result.runtimeType}',
        ['Future<void>'],
      );
    }

    await pre();

    await result;

    await post();

    return response;
  }
}
