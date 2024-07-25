part of './router.dart';

class RunCatchers {
  const RunCatchers(this.helper);

  final RouterHelperMixin helper;

  Future<ReadOnlyResponse> call(
    Object e,
    StackTrace stackTrace, {
    ReadOnlyResponse? defaultResponse,
  }) =>
      run(e, stackTrace);

  Future<ReadOnlyResponse> run(
    Object e,
    StackTrace stackTrace, {
    ReadOnlyResponse? defaultResponse,
  }) async {
    final RouterHelperMixin(
      :catchers,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextHelperMixin(exceptionCatcher: context),
    ) = helper;

    defaultResponse ??= defaultResponses.internalServerError;

    if (e is! Exception) {
      return debugErrorResponse(
        defaultResponse,
        error: e,
        stackTrace: stackTrace,
      );
    }

    for (final catcher in catchers) {
      if (!catcher.canCatch(e)) {
        continue;
      }

      final result = catcher.catchException(
        e,
        context,
        const ExceptionCatcherAction(),
      );

      if (result.isHandled) {
        final (statusCode, headers, body) =
            result.asHandled.getResponseOverrides();

        return debugErrorResponse(
          response
            .._overrideWith(
              statusCode: statusCode,
              backupCode: 500,
              headers: headers,
              body: body,
            ),
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return helper.debugErrorResponse(
      defaultResponse,
      error: e,
      stackTrace: stackTrace,
    );
  }
}
