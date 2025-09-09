part of 'router.dart';

class RunMiddlewares {
  const RunMiddlewares(this.helper);

  final HelperMixin helper;

  Future<ReadOnlyResponse?> call() => run();

  Future<ReadOnlyResponse?> run() async {
    final HelperMixin(
      :middlewares,
      :response,
      :debugErrorResponse,
      context: ContextMixin(main: context),
    ) = helper;

    for (final middleware in middlewares) {
      final result = await middleware.use(context);

      if (result.isStop) {
        final (statusCode, headers, body) =
            result.asStop.getResponseOverrides();

        return debugErrorResponse(
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
