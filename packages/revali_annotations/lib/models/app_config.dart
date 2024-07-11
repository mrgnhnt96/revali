import 'dart:io';

base class AppConfig {
  const AppConfig({
    required this.host,
    required this.port,
    this.prefix = _defaultPrefix,
    this.onServerStarted,
  })  : securityContext = null,
        requestClientCertificate = false;

  const AppConfig.secure({
    required this.host,
    required this.port,
    required SecurityContext this.securityContext,
    this.requestClientCertificate = false,
    this.prefix = _defaultPrefix,
    this.onServerStarted,
  });

  factory AppConfig.defaultApp() = _DefaultApp;

  static const String _defaultPrefix = 'api';

  final String host;
  final int port;
  final String? prefix;
  final void Function(HttpServer)? onServerStarted;
  final bool requestClientCertificate;
  final SecurityContext? securityContext;
}

final class _DefaultApp extends AppConfig {
  _DefaultApp()
      : super(
          host: 'localhost',
          port: 8080,
          onServerStarted: (server) {
            print(
              'Serving at http://${server.address.host}:${server.port}/${AppConfig._defaultPrefix}',
            );
          },
        );
}
