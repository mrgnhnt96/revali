part of 'router.dart';

class RunOriginCheck {
  const RunOriginCheck(this.helper);

  final HelperMixin helper;

  Response? call() => run();

  Response? run() {
    final HelperMixin(
      :request,
      :route,
      :debugErrorResponse,
      :defaultResponses,
      :preventedHeaders,
      :expectedHeaders,
      :allowedOrigins,
      :response,
    ) = helper;

    var isAllowed = true;
    final origin = request.headers.origin;
    // CORS governs browser cross-origin behavior. A request with no Origin
    // header (native mobile/desktop clients, curl, server-to-server calls)
    // isn't a cross-origin browser request, so it's never subject to origin
    // allowlisting -- restricting @AllowOrigins to a web frontend's origin
    // must not also lock out every non-browser client of the same endpoint.
    if (origin != null && allowedOrigins.isNotEmpty) {
      isAllowed = false;

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

    if (preventedHeaders.isNotEmpty) {
      for (final header in request.headers.keys) {
        if (preventedHeaders.contains(header)) {
          return debugErrorResponse(
            defaultResponses.failedCorsHeaders,
            error: 'Header is not allowed.',
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

    final headers = expectedHeaders.followedBy(allowedHeadersFromRequest ?? []);

    if (headers.isNotEmpty) {
      response.headers.set(
        HttpHeaders.accessControlAllowHeadersHeader,
        headers.toSet().join(', '),
      );
    }

    return null;
  }
}
