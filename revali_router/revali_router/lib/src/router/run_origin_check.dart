part of 'router.dart';

class RunOriginCheck {
  const RunOriginCheck(this.helper);

  final HelperMixin helper;

  ReadOnlyResponse? call() => run();

  ReadOnlyResponse? run() {
    final HelperMixin(
      :request,
      :route,
      :debugErrorResponse,
      :defaultResponses,
      :allowedHeaders,
      :allowedOrigins,
    ) = helper;

    var isAllowed = true;
    final origin = request.headers.origin;
    if (allowedOrigins.isNotEmpty) {
      isAllowed = false;

      if (origin == null) {
        if (!allowedOrigins.contains('*')) {
          return debugErrorResponse(
            defaultResponses.failedCors,
            error: 'Origin header is missing.',
            stackTrace: StackTrace.current,
          );
        }

        isAllowed = true;
      } else {
        for (final pattern in allowedOrigins) {
          if (pattern == '*' || pattern == origin) {
            isAllowed = true;
            break;
          }

          try {
            final regex = RegExp(pattern);
            if (regex.hasMatch(origin)) {
              isAllowed = true;
              break;
            }
          } catch (_) {
            // ignore the pattern if it is not a valid regex
          }
        }
      }
    }

    if (!isAllowed) {
      return debugErrorResponse(
        defaultResponses.failedCors,
        error: 'Origin is not allowed.',
        stackTrace: StackTrace.current,
      );
    }

    // check for allowed headers
    if (allowedHeaders.isNotEmpty) {
      final caseSafeHeaders = CaseInsensitiveMap.from({
        for (final header in allowedHeaders) header: header,
        for (final header in const AllowHeaders.simple().headers)
          header: header,
      });

      final headers = request.headers;
      for (final header in headers.keys) {
        if (!caseSafeHeaders.containsKey(header)) {
          return debugErrorResponse(
            defaultResponses.failedCors,
            error: 'Header "$header" is not allowed.',
            stackTrace: StackTrace.current,
          );
        }
      }
    }

    if (origin != null) {
      request.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    }

    request.headers
      ..set(
        HttpHeaders.accessControlAllowMethodsHeader,
        route.allowedMethods.join(', '),
      )
      ..set(HttpHeaders.accessControlAllowCredentialsHeader, 'true')
      ..set(
        HttpHeaders.accessControlAllowHeadersHeader,
        allowedHeaders.join(', '),
      );

    return null;
  }
}
