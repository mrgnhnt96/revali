import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_core/revali_core.dart';

/// Ensures every request has an ID header (default `X-Request-Id`).
///
/// Apply on an app, controller, or endpoint:
///
/// ```dart
/// @RequestId()
/// @App()
/// class MyApp extends AppConfig { ... }
/// ```
///
/// The id it sets is [TraceContext.current]'s, so the header and the ambient
/// context always name the same request — two ids for one request is worse
/// than none. That also means the context is available whether or not this kit
/// is applied: the kit puts the id *on the request*, while the context exists
/// for every request either way.
///
/// CORS remains `@AllowOrigins` — use that for cross-origin setup.
final class RequestId implements LifecycleComponent {
  const RequestId([this.headerName = TraceContext.requestIdHeader]);

  final String headerName;

  InterceptorPreResult ensureId(Headers headers) {
    final existing = headers[headerName];
    if (existing == null || existing.isEmpty) {
      headers.set(
        headerName,
        TraceContext.current?.requestId ?? TraceContext.newRequestId(),
      );
    }
  }
}
