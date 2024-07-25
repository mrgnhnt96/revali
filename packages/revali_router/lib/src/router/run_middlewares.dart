part of 'router.dart';

class RunMiddlewares {
  const RunMiddlewares(this.helper);

  final RouterHelperMixin helper;

  Future<ReadOnlyResponse?> call() => run();

  Future<ReadOnlyResponse?> run() async {
    final RouterHelperMixin(
      :middlewares,
      :response,
      :debugErrorResponse,
      context: ContextHelperMixin(middleware: context),
    ) = helper;

    for (final middleware in middlewares) {
      final result = await middleware.use(context, const MiddlewareAction());

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
