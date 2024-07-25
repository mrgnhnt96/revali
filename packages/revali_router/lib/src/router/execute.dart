part of 'router.dart';

class Execute {
  const Execute(this.helper);

  final RouterHelperMixin helper;

  Future<ReadOnlyResponse> call() => run();

  Future<ReadOnlyResponse> run() async {
    final RouterHelperMixin(
      :route,
      :request,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextHelperMixin(endpoint: context),
      run: RunnersHelperMixin(
        :interceptors,
        :guards,
        :middlewares,
        :handleWebSocket,
      ),
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

    if (await middlewares() case final response?) {
      return response;
    }

    if (await guards() case final response?) {
      return response;
    }

    if (route is WebSocketRoute) {
      return handleWebSocket(await handler(context)).execute();
    }

    await interceptors.pre();

    await handler(context);

    await interceptors.post();

    return response;
  }
}
