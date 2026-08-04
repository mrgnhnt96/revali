import 'dart:math';

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
/// CORS remains `@AllowOrigins` — use that for cross-origin setup.
final class RequestId implements LifecycleComponent {
  const RequestId([this.headerName = 'X-Request-Id']);

  final String headerName;

  InterceptorPreResult ensureId(Headers headers) {
    final existing = headers[headerName];
    if (existing == null || existing.isEmpty) {
      headers.set(headerName, _generateId());
    }
  }

  static String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
