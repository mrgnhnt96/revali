import 'package:revali_client/src/http_interceptor.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

/// Adds headers computed per request, rather than fixed when the client is
/// built.
///
/// The motivating case is correlation. A server handling a request and calling
/// a peer should pass its trace headers along, but those differ for every
/// request, so they cannot be baked into the client at construction. This
/// takes a callback instead, invoked per request:
///
/// ```dart
/// // On a server, where revali_core is available:
/// final client = Server(
///   client: HttpPackageClient(
///     interceptors: [
///       HeaderInterceptor(
///         () => TraceContext.current?.outboundHeaders() ?? const {},
///       ),
///     ],
///   ),
/// );
/// ```
///
/// The callback is deliberately how this is wired: `revali_client` runs on the
/// web, where `dart:io` — and so `revali_core` — cannot follow, so the trace
/// type cannot be imported here. A function of `Map<String, String>` couples
/// the two without dragging a server-only dependency into a browser bundle.
class HeaderInterceptor implements HttpInterceptor {
  const HeaderInterceptor(this.headers);

  /// Called once per request, just before it is sent.
  final Map<String, String> Function() headers;

  @override
  void onRequest(HttpRequest request) {
    headers().forEach((key, value) {
      // Never clobbers a header the call site set explicitly: an ambient
      // default losing to an argument is the behaviour a caller expects, and
      // the reverse is very hard to debug.
      request.headers.putIfAbsent(key, () => value);
    });
  }

  @override
  void onResponse(HttpResponse response) {}
}
