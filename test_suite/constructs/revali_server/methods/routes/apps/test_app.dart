import 'dart:io';

import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://www.revali.dev/revali/app-configuration/overview
@App(flavor: 'test')
final class TestApp extends AppConfig {
  // Port 0 → ephemeral; avoids colliding with other local listeners on 8080
  // (IPv4 dual-stack checks in bind_server_e2e_test would otherwise hit them).
  const TestApp() : super(host: 'localhost', port: 0);

  @override
  void onServerStarted(HttpServer server) {}
}
