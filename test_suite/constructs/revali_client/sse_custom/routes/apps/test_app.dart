import 'dart:io';

import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://docs.revali.dev/revali/app-configuration/
@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 8080);

  @override
  void onServerStarted(HttpServer server) {}
}
