part of 'router.dart';

class RunMiddlewares {
  const RunMiddlewares(this.helper);

  final HelperMixin helper;

  Future<Response?> call() => run();

  Future<Response?> run() async {
    final HelperMixin(
      :middlewares,
      :response,
      :debugErrorResponse,
      :authoredErrorResponse,
      context: ContextMixin(main: context),
    ) = helper;

    for (final middleware in middlewares) {
      final result = await middleware.use(context);

      if (result.isStop) {
        final overrides = result.asStop.getResponseOverrides();
        final (statusCode, headers, body) = overrides;

        // A middleware that stopped with a status or a body of its own wrote
        // this response deliberately -- shedding load, say -- so it survives a
        // released build.
        final formatResponse =
            overrides.areAuthored ? authoredErrorResponse : debugErrorResponse;

        return formatResponse(
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
