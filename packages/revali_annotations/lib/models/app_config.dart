import 'dart:io';

base class AppConfig {
  const AppConfig({
    required this.host,
    required this.port,
    this.onServerStarted,
  });

  factory AppConfig.defaultApp() = _DefaultApp;

  final String host;
  final int port;
  final void Function(HttpServer)? onServerStarted;
}

final class _DefaultApp extends AppConfig {
  _DefaultApp()
      : super(
          host: 'localhost',
          port: 8080,
          onServerStarted: (server) {
            print('Serving at http://${server.address.host}:${server.port}');
          },
        );
}
