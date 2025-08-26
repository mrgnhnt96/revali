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
    final allowedHeadersFromRequest = request.headers.getAll(
      HttpHeaders.accessControlRequestHeadersHeader,
    );

    // TODO(mrgnhnt): Blacklist headers

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
          error: '''
Missing Headers:
  - ${caseSafeHeaders.keys.join('\n  - ')}
''',
          stackTrace: StackTrace.current,
        );
      }
    }

    response.headers.set(
      HttpHeaders.accessControlAllowCredentialsHeader,
      'true',
    );

    if (origin != null) {
      response.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    } else {
      response.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');
    }

    if (route.allowedMethods case final methods when methods.isNotEmpty) {
      response.headers.set(
        HttpHeaders.accessControlAllowMethodsHeader,
        route.allowedMethods.join(', '),
      );
    }

    if (route.allowedMethods case final methods when methods.isNotEmpty) {
      response.headers.set(
        HttpHeaders.allowHeader,
        methods.join(', '),
      );
    }

    final headers = allowedHeaders
        .followedBy(expectedHeaders)
        .followedBy(allowedHeadersFromRequest ?? []);

    if (headers.isNotEmpty) {
      response.headers.set(
        HttpHeaders.accessControlAllowHeadersHeader,
        headers.toSet().join(', '),
      );
    }

    return null;
  }
}
