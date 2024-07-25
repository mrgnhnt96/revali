part of 'router.dart';

class _RunGuards {
  const _RunGuards(this.helper);

  final RouterHelperMixin helper;

  Future<ReadOnlyResponse?> call() => run();

  Future<ReadOnlyResponse?> run() async {
    final RouterHelperMixin(
      :request,
      :guards,
      :response,
      :dataHandler,
      :directMeta,
      :inheritedMeta,
      :route,
      :debugErrorResponse,
    ) = helper;

    for (final guard in guards) {
      final result = await guard.canActivate(
        GuardContextImpl(
          meta: GuardMetaImpl(
            direct: directMeta,
            inherited: inheritedMeta,
            route: route,
          ),
          response: response,
          request: request,
          data: dataHandler,
        ),
        const GuardAction(),
      );

      if (result.isNo) {
        final (statusCode, headers, body) = result.asNo.getResponseOverrides();

        return debugErrorResponse(
          response
            .._overrideWith(
                statusCode: statusCode,
                backupCode: 403,
                headers: headers,
                body: body),
          error: GuardStopException('${guard.runtimeType}'),
          stackTrace: StackTrace.current,
        );
      }
    }

    return null;
  }
}
