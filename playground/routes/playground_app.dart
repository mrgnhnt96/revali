import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
final class PlaygroundApp extends AppConfig {
  PlaygroundApp()
    : super(
        host: 'localhost',
        port: 8090,
        // Single isolate while stressing hot reload; multi-worker respawn
        // is a separate failure mode.
        workers: 1,
      );
}
