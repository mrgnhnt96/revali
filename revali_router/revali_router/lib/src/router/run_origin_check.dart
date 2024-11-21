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
      :expectedHeaders,
      :allowedOrigins,
      :response,
    ) = helper;

    var isAllowed = true;
    final origin = request.headers.origin;
    if (allowedOrigins.isNotEmpty) {
      isAllowed = false;

      if (origin == null) {
        if (!allowedOrigins.contains('*')) {
          return debugErrorResponse(
            defaultResponses.failedCorsOrigin,
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
        defaultResponses.failedCorsOrigin,
        error: 'Origin is not allowed.',
        stackTrace: StackTrace.current,
      );
    }

    // check for allowed headers
    if (allowedHeaders.isNotEmpty) {
      final caseSaveExpectedHeaders = CaseInsensitiveMap.from({
        for (final header in expectedHeaders) header: header,
      });

      final caseSafeHeaders = CaseInsensitiveMap.from(
        {
          for (final header in allowedHeaders) header: header,
        },
      );

      final headers = request.headers;
      for (final header in headers.keys) {
        if (!caseSafeHeaders.containsKey(header)) {
          if (caseSaveExpectedHeaders.containsKey(header)) continue;

          return debugErrorResponse(
            defaultResponses.failedCorsHeaders,
            error: 'Header "$header" is not allowed.',
            stackTrace: StackTrace.current,
          );
        }
      }
    }

    if (expectedHeaders.isNotEmpty) {
      final caseSafeHeaders = CaseInsensitiveMap.from({
        for (final header in expectedHeaders) header: header,
      });

      final headers = request.headers;
      for (final header in headers.keys) {
        caseSafeHeaders.remove(header);
      }

      if (caseSafeHeaders.isNotEmpty) {
        return debugErrorResponse(
          defaultResponses.failedCorsHeaders,
          error:
              'Header(s) "${caseSafeHeaders.keys.join(', ')}" is/are missing.',
          stackTrace: StackTrace.current,
        );
      }
    }

    if (origin != null) {
      response.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    }

    response.headers
      ..set(
        HttpHeaders.accessControlAllowMethodsHeader,
        route.allowedMethods.join(', '),
      )
      ..set(
        HttpHeaders.allowHeader,
        route.allowedMethods.join(', '),
      )
      ..set(HttpHeaders.accessControlAllowCredentialsHeader, 'true')
      ..set(
        HttpHeaders.accessControlAllowHeadersHeader,
        allowedHeaders.followedBy(expectedHeaders).join(', '),
      );

    return null;
  }
}
