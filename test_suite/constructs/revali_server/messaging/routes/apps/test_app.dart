import 'dart:io';

import 'package:revali_router/revali_router.dart';

/// The broker the generated server subscribes to.
///
/// Held statically so a test can publish into the same instance the server
/// consumed from; a real app would connect to Redis here instead.
class TestBroker {
  static InMemoryBroker? instance;

  /// Set to false to prove messaging is opt-in.
  static bool enabled = true;
}

@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 0);

  @override
  Future<MessageBroker?> createBroker() async {
    if (!TestBroker.enabled) {
      return null;
    }

    return TestBroker.instance = InMemoryBroker();
  }

  @override
  void onServerStarted(HttpServer server) {}
}
