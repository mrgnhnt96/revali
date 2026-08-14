import 'dart:io';

import 'package:revali_router/revali_router.dart';

@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 8080);

  @override
  void onServerStarted(HttpServer server) {}
}
