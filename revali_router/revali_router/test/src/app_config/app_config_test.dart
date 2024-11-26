import 'dart:io';

import 'package:revali_router/src/app_config/app_config.dart';
import 'package:revali_router/src/response/default_responses.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig', () {
    test('should create AppConfig with required parameters', () {
      const appConfig = AppConfig(
        host: 'localhost',
        port: 8080,
      );

      expect(appConfig.host, 'localhost');
      expect(appConfig.port, 8080);
      expect(appConfig.prefix, 'api');
    });

    test('should create secure AppConfig with required parameters', () {
      final securityContext = SecurityContext();
      final appConfig = AppConfig.secure(
        host: 'localhost',
        port: 8080,
        securityContext: securityContext,
      );

      expect(appConfig.host, 'localhost');
      expect(appConfig.port, 8080);
      expect(appConfig.securityContext, securityContext);
      expect(appConfig.requestClientCertificate, false);
      expect(appConfig.prefix, 'api');
    });

    test('should create default AppConfig', () {
      final appConfig = AppConfig.defaultApp();

      expect(appConfig.host, isNotNull);
      expect(appConfig.port, isNotNull);
    });

    test('should return default responses', () {
      const appConfig = AppConfig(
        host: 'localhost',
        port: 8080,
      );

      expect(appConfig.defaultResponses, isA<DefaultResponses>());
    });
  });
}
