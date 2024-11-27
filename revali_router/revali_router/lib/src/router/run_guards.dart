part of 'router.dart';

class RunGuards {
  const RunGuards(this.helper);

  final HelperMixin helper;

  Future<ReadOnlyResponse?> call() => run();

  Future<ReadOnlyResponse?> run() async {
    final HelperMixin(
      :guards,
      :response,
      context: ContextMixin(guard: context),
      :debugErrorResponse,
    ) = helper;

    for (final guard in guards) {
      final result = await guard.protect(context);

      if (result.isBlock) {
        final (statusCode, headers, body) =
            result.asBlock.getResponseOverrides();

        return debugErrorResponse(
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
