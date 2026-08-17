part of 'router.dart';

class RunGuards {
  const RunGuards(this.helper);

  final HelperMixin helper;

  Future<Response?> call() => run();

  Future<Response?> run() async {
    final HelperMixin(
      :guards,
      :response,
      context: ContextMixin(main: context),
      :debugErrorResponse,
      :authoredErrorResponse,
    ) = helper;

    for (final guard in guards) {
      final result = await guard.protect(context);

      if (result.isBlock) {
        final overrides = result.asBlock.getResponseOverrides();
        final (statusCode, headers, body) = overrides;

        // A guard that blocked with a status or a body of its own wrote this
        // response deliberately, so it survives a released build.
        final formatResponse =
            overrides.areAuthored ? authoredErrorResponse : debugErrorResponse;

        return formatResponse(
          response
            .._overrideWith(
              statusCode: statusCode,
              backupCode: 403,
              headers: headers,
              body: body,
            ),
          error: GuardStopException('${guard.runtimeType}'),
          stackTrace: StackTrace.current,
        );
      }
    }

    return null;
  }
}
