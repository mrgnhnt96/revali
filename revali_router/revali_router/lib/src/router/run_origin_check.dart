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

  Response _refuse(Response refusal, {required Object error}) {
    final response = helper.debugErrorResponse(
      refusal,
      error: error,
      stackTrace: StackTrace.current,
    );

    _varyOnOrigin(response);

    return response;
  }

  /// Marks [response] as depending on the request's `Origin`, so a cache never
  /// hands one origin's answer to another. Refusals need it too: a cached 403
  /// would otherwise lock out an admitted origin.
  ///
  /// Appends rather than sets, and leaves a marked response alone, because a
  /// refusal can be an app-supplied response shared between requests.
  void _varyOnOrigin(Response response) {
    if (helper.request.headers.origin == null) {
      return;
    }

    final headers = response.headers;
    final values = [
      for (final value in headers.getAll(HttpHeaders.varyHeader) ?? <String>[])
        value.trim(),
    ];

    if (values.any((value) => value.toLowerCase() == 'origin')) {
      return;
    }

    headers.set(HttpHeaders.varyHeader, [...values, 'Origin'].join(', '));
  }

  Response? run() {
    final HelperMixin(
      :request,
      :route,
      :defaultResponses,
      :preventedHeaders,
      :expectedHeaders,
      :allowedOrigins,
      :cors,
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
      return _refuse(
        defaultResponses.failedCorsOrigin,
        error: 'Origin is not allowed.',
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
          return _refuse(
            defaultResponses.failedCorsHeaders,
            error: 'Header is not allowed.',
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
        return _refuse(
          defaultResponses.failedCorsHeaders,
          error: '''
Missing Headers:
  - ${caseSafeHeaders.keys.join('\n  - ')}
''',
        );
      }
    }

    final grant = cors.grant(origin);

    response.headers.set(
      HttpHeaders.accessControlAllowOriginHeader,
      grant.allowOrigin,
    );

    if (grant.allowCredentials) {
      response.headers.set(
        HttpHeaders.accessControlAllowCredentialsHeader,
        'true',
      );
    }

    _varyOnOrigin(response);

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
