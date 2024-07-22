part of 'router.dart';

extension IsOriginAllowed on Router {
  ReadOnlyResponse? isOriginAllowed(
    MutableRequest request,
    Route route, {
    required Set<String>? globalAllowedOrigins,
    required Set<String>? globalAllowedHeaders,
  }) {
    final inheritGlobal = route.allowedOrigins?.inherit != false;
    final allAllowedOrigins = {
      if (inheritGlobal) ...?globalAllowedOrigins,
      ...route.allAllowedOrigins
    };

    var isAllowed = true;
    final origin = request.headers.origin;
    if (allAllowedOrigins case final allowedOrigins
        when allowedOrigins.isNotEmpty) {
      isAllowed = false;

      if (origin == null) {
        if (!allowedOrigins.contains('*')) {
          return _debugResponse(
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
      return _debugResponse(
        defaultResponses.failedCors,
        error: 'Origin is not allowed.',
        stackTrace: StackTrace.current,
      );
    }

    if (origin != null) {
      request.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    }

    request.headers
      ..set(HttpHeaders.accessControlAllowMethodsHeader,
          route.allowedMethods.join(', '))
      ..set(HttpHeaders.accessControlAllowCredentialsHeader, 'true')
      ..set(
          HttpHeaders.accessControlAllowHeadersHeader,
          {
            if (inheritGlobal) ...?globalAllowedHeaders,
            ...?route.allowedHeaders?.headers,
          }.join(', '));

    return null;
  }
}
