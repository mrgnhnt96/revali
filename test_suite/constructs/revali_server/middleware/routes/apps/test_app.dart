import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/pre_interceptor.dart';

// Learn more about Apps at https://www.revali.dev/revali/app-configuration/overview
@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton(Logger.new);
  }

  @override
  void onServerStarted(HttpServer server) {}
}
