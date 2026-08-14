import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Extends the `revali_router` AppConfig, which is the one apps actually
/// extend — `revali_router` re-exports `revali_core` with `AppConfig` hidden.
final class _App extends AppConfig {
  _App({super.env}) : super.fromEnv();
}

void main() {
  group('AppConfig.fromEnv', () {
    test('is reachable from the class apps extend', () {
      // Regression: this constructor existed only on the core AppConfig at
      // first, so a core unit test passed while every real app failed to
      // compile with "Superclass has no constructor named
      // AppConfig.fromEnv".
      final app = _App(env: Env({'PORT': '9000'}));

      expect(app.host, '0.0.0.0');
      expect(app.port, 9000);
    });

    test('still carries the router defaults', () {
      final app = _App(env: Env({}));

      expect(app.defaultResponses, isA<DefaultResponses>());
      expect(app.trustedProxy, isA<TrustedProxy>());
    });
  });
}
