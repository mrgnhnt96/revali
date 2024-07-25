part of 'router.dart';

class Execute {
  const Execute(
    this.helper,
    this.context,
  );

  final RouterHelperMixin helper;
  final ContextHelperMixin context;

  Future<ReadOnlyResponse> call() => run();

  Future<ReadOnlyResponse> run() async {
    final RouterHelperMixin(
      :route,
      :request,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextHelperMixin(endpoint: endpointContext),
      :runInterceptors,
      :handleWebSocket,
    ) = helper;

    final handler = route.handler;
    if (handler == null) {
      return debugErrorResponse(
        defaultResponses.notFound,
        error: MissingHandlerException(
          method: request.method,
          path: request.segments.join('/'),
        ),
        stackTrace: StackTrace.current,
      );
    }

    if (await helper.runMiddlewares() case final response?) {
      return response;
    }

    if (await helper.runGuards() case final response?) {
      return response;
    }

    if (route is WebSocketRoute) {
      return handleWebSocket(await handler(endpointContext)).execute();
    }

    await runInterceptors.pre();

    await handler(endpointContext);

    await runInterceptors.post();

    return response;
  }
}
