part of 'router.dart';

extension RunGuards on Router {
  Future<ReadOnlyResponse?> runGuards(
    List<Guard> guards, {
    required MutableRequest request,
    required MutableResponse response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
    required Route route,
  }) async {
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

        return _debugResponse(
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
