part of 'router.dart';

class RunOriginCheck {
  const RunOriginCheck(this.helper);

  final HelperMixin helper;

  Response? call() => run();

  /// Whether [origin] is admitted by one `@AllowOrigins` entry.
  ///
  /// An entry is `*`, an exact origin, or -- only when it starts with `^` -- a
  /// regular expression that must match the whole origin. A plain origin is
  /// never read as a regular expression: its dots would match any character,
  /// and an unanchored match would admit any origin that merely contains it
  /// (`https://myapp.com` admitting `https://myapp.com.attacker.io`).
  static bool _originMatches(String pattern, String origin) {
    if (pattern == '*' || pattern == origin) {
      return true;
    }

    if (!pattern.startsWith('^')) {
      return false;
    }

    try {
      return RegExp('^(?:$pattern)\$').hasMatch(origin);
    } catch (_) {
      // ignore the pattern if it is not a valid regex
      return false;
    }
  }

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
        if (_originMatches(pattern, origin)) {
          isAllowed = true;
          break;
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

    // Header names are case-insensitive, and dart:io delivers them lowercased.
    final prevented = {
      for (final header in preventedHeaders) header.toLowerCase(),
    };

    // A browser preflight never carries the headers of the real request -- it
    // only names them in Access-Control-Request-Headers -- so checking for
    // their presence here would refuse every preflight. The real request that
    // follows is still checked.
    final isPreflight = request.method == 'OPTIONS' &&
        request.headers.get(HttpHeaders.accessControlRequestMethodHeader) !=
            null;

    if (prevented.isNotEmpty && !isPreflight) {
      for (final header in request.headers.keys) {
        if (prevented.contains(header.toLowerCase())) {
          return debugErrorResponse(
            defaultResponses.failedCorsHeaders,
            error: 'Header is not allowed.',
            stackTrace: StackTrace.current,
          );
        }
      }
    }

    if (expectedHeaders.isNotEmpty && !isPreflight) {
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

    final headers = expectedHeaders
        .followedBy(
          allowedHeadersFromRequest
                  ?.map((header) => header.trim())
                  .where((header) => header.isNotEmpty) ??
              [],
        )
        .where((header) => !prevented.contains(header.toLowerCase()));

    if (headers.isNotEmpty) {
      response.headers.set(
        HttpHeaders.accessControlAllowHeadersHeader,
        headers.toSet().join(', '),
      );
    }

    return null;
  }
}
