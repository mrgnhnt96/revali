import 'dart:async';

import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

/// Observes and rewrites requests on their way out and responses on the way
/// back.
///
/// Both hooks may **replace** what they are given, which is what makes
/// caching, stubbing and short-circuiting possible at all. Returning `null` —
/// the common case — means "carry on with what you were given".
///
/// ```dart
/// class Offline implements HttpInterceptor {
///   const Offline();
///
///   @override
///   HttpResponse? onRequest(HttpRequest request) {
///     // Answer from a cache without ever hitting the network.
///     return cached[request.url];
///   }
///
///   @override
///   HttpResponse? onResponse(HttpResponse response) => null;
/// }
/// ```
///
/// Errors are **not** caught. An interceptor that fails has not done its job,
/// and letting the request continue would send it in whatever half-prepared
/// state it was left in — an auth interceptor that throws would otherwise put
/// an unauthenticated request on the wire and surface as a puzzling 401 from
/// the peer.
abstract interface class HttpInterceptor {
  const HttpInterceptor();

  /// Runs before the request is sent.
  ///
  /// Mutate [request] to change what goes out. Return a response to answer
  /// without sending anything — later interceptors are skipped — or `null` to
  /// continue.
  FutureOr<HttpResponse?> onRequest(HttpRequest request);

  /// Runs after a response arrives.
  ///
  /// Return a replacement to substitute it, or `null` to keep it as is.
  FutureOr<HttpResponse?> onResponse(HttpResponse response);
}
