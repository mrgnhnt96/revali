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

    Future<dynamic> result;

    result = handler.call(helper.endpointContext);

    if (route is WebSocketRoute) {
      if (result is! Future<WebSocketHandler>) {
        throw InvalidHandlerResultException('${result.runtimeType}', [
          '$WebSocketHandler',
          'Future<$WebSocketHandler>',
        ]);
      }

      return helper.handleWebSocket(result);
    }

    final RouterHelperMixin(:runInterceptors) = helper;

    await runInterceptors.pre();

    await result;

    await runInterceptors.post();

    return response;
  }
}
