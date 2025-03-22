import 'dart:io';

import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://www.revali.dev/revali/app-configuration/overview
@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 2534);

  @override
  void onServerStarted(HttpServer server) {}
}
