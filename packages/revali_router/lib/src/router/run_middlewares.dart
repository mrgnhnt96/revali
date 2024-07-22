part of 'router.dart';

extension RunMiddlewares on Router {
  Future<ReadOnlyResponse?> runMiddlewares(
    List<Middleware> middlewares, {
    required MutableRequest request,
    required MutableResponse response,
    required DataHandler dataHandler,
  }) async {
    for (final middleware in middlewares) {
      final result = await middleware.use(
        MiddlewareContextImpl(
          request: request,
          response: response,
          data: dataHandler,
        ),
        const MiddlewareAction(),
      );

      if (result.isStop) {
        final (statusCode, headers, body) =
            result.asStop.getResponseOverrides();

        return _debugResponse(
          response
            .._overrideWith(
              statusCode: statusCode,
              backupCode: 400,
              headers: headers,
              body: body,
            ),
          error: MiddlewareStopException('${middleware.runtimeType}'),
          stackTrace: StackTrace.current,
        );
      }
    }
    return null;
  }
}
