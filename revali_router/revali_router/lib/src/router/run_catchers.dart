part of './router.dart';

class RunCatchers {
  const RunCatchers(this.helper);

  final HelperMixin helper;

  Future<Response> call(
    Object e,
    StackTrace stackTrace, {
    Response? defaultResponse,
  }) =>
      run(
        e,
        stackTrace,
        defaultResponse: defaultResponse,
      );

  Future<Response> run(
    Object e,
    StackTrace stackTrace, {
    Response? defaultResponse,
  }) async {
    try {
      return await _run(e, stackTrace, defaultResponse: defaultResponse);
    } catch (e) {
      final HelperMixin(
        :defaultResponses,
      ) = helper;

      return helper.debugErrorResponse(
        defaultResponse ?? defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> _run(
    Object e,
    StackTrace stackTrace, {
    Response? defaultResponse,
  }) async {
    final HelperMixin(
      :catchers,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextMixin(main: context),
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

      final result = catcher.catchException(e, context);

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

    return debugErrorResponse(
      defaultResponse,
      error: e,
      stackTrace: stackTrace,
    );
  }
}
