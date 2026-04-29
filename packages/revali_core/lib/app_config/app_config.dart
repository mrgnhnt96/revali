// ignore_for_file: avoid_print

import 'dart:io';

import 'package:revali_core/revali_core.dart';

abstract base class AppConfig {
  const AppConfig({
    required this.host,
    required this.port,
    this.prefix = _defaultPrefix,
  })  : securityContext = null,
        requestClientCertificate = false;

  const AppConfig.secure({
    required this.host,
    required this.port,
    required SecurityContext this.securityContext,
    this.requestClientCertificate = false,
    this.prefix = _defaultPrefix,
  });

  const AppConfig.defaultApp()
      : this(
          host: 'localhost',
          port: 8080,
        );

  static const String _defaultPrefix = 'api';

  final String host;
  final int port;
  final String? prefix;
  final bool requestClientCertificate;
  final SecurityContext? securityContext;

  DI initializeDI() => DIImpl();

  void onServerStarted(HttpServer server) {
    var prefix = '';
    if (this.prefix case final p?) {
      prefix = '/$p';
    }

    print(
      'Serving at http://${server.address.host}:${server.port}$prefix',
    );
  }

  Future<void> configureDependencies(covariant DI di) async {}

  /// Runs the async server startup sequence (bind, DI, routes, listen).
  ///
  /// The default implementation calls [start] as-is. Override to wrap [start]
  /// (for example with `runZoned` from `dart:async`) so that the entire startup
  /// runs inside a custom zone.
  Future<HttpServer> runStartup(Future<HttpServer> Function() start) => start();
}
