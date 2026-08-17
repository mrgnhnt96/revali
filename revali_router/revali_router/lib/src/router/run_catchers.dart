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
      :authoredErrorResponse,
      :defaultResponses,
      context: ContextMixin(main: context),
    ) = helper;

    // Binding failures are client errors unless a catcher handles them.
    final fallback = defaultResponse ??
        (e is MissingArgumentException
            ? defaultResponses.badRequest
            : defaultResponses.internalServerError);

    // Handled after the catcher loop below, not here: an app that registered a
    // catcher for its own HttpError subtype should still win.

    if (e is! Exception) {
      return debugErrorResponse(
        fallback,
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
        final overrides = result.asHandled.getResponseOverrides();
        final (statusCode, headers, body) = overrides;

        // A catcher that wrote a status or an envelope decided this response;
        // one that returned a bare `handled()` left it to the fallback below.
        final formatResponse =
            overrides.areAuthored ? authoredErrorResponse : debugErrorResponse;

        return formatResponse(
          response
            .._overrideWith(
              statusCode: statusCode,
              backupCode: e is MissingArgumentException ? 400 : 500,
              headers: headers,
              body: body,
            ),
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // No catcher claimed it. A structured failure carries its own status and
    // envelope, so the caller gets a code to branch on instead of a status
    // and a sentence.
    if (e is HttpError) {
      return authoredErrorResponse(
        response
          .._overrideWith(
            statusCode: e.statusCode,
            backupCode: e.statusCode,
            headers: null,
            body: e.toEnvelope(),
          ),
        error: e,
        stackTrace: stackTrace,
      );
    }

    return debugErrorResponse(
      fallback,
      error: e,
      stackTrace: stackTrace,
    );
  }
}
