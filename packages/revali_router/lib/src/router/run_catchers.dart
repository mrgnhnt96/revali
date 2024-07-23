part of 'router.dart';

extension RunCatchers on Router {
  Future<ReadOnlyResponse?> runCatcher(
    List<ExceptionCatcher> catchers, {
    required Exception e,
    required StackTrace stackTrace,
    required MutableRequest request,
    required MutableResponse response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
    required BaseRoute route,
  }) async {
    for (final catcher in catchers) {
      if (!catcher.canCatch(e)) {
        continue;
      }

      final result = await catcher.catchException(
        e,
        ExceptionCatcherContextImpl(
          data: dataHandler,
          meta: ExceptionCatcherMetaImpl(
            direct: directMeta,
            inherited: inheritedMeta,
            route: route,
          ),
          request: request,
          response: response,
        ),
        const ExceptionCatcherAction(),
      );

      if (result.isHandled) {
        final (statusCode, headers, body) =
            result.asHandled.getResponseOverrides();

        return _debugResponse(
          response
            .._overrideWith(
                statusCode: statusCode,
                backupCode: 500,
                headers: headers,
                body: body),
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return null;
  }
}
