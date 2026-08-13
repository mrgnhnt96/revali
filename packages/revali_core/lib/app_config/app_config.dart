// ignore_for_file: avoid_print

import 'dart:io';

import 'package:revali_core/revali_core.dart';

abstract base class AppConfig {
  const AppConfig({
    required this.host,
    required this.port,
    this.prefix = _defaultPrefix,
    this.workers = 1,
    this.backlog = 0,
  })  : securityContext = null,
        requestClientCertificate = false,
        assert(workers >= 1, 'workers must be >= 1'),
        assert(backlog >= 0, 'backlog must be >= 0');

  const AppConfig.secure({
    required this.host,
    required this.port,
    required SecurityContext this.securityContext,
    this.requestClientCertificate = false,
    this.prefix = _defaultPrefix,
    this.workers = 1,
    this.backlog = 0,
  })  : assert(workers >= 1, 'workers must be >= 1'),
        assert(backlog >= 0, 'backlog must be >= 0');

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

  /// Number of isolates that accept connections on [port].
  ///
  /// When greater than 1, each isolate binds with `shared: true` so the OS
  /// distributes connections across workers. Defaults to 1 (single isolate).
  final int workers;

  /// Listen backlog passed to [HttpServer.bind] / [HttpServer.bindSecure].
  ///
  /// `0` means use the OS default. Raise under connection bursts when using
  /// multiple [workers].
  final int backlog;

  DI initializeDI() => DIImpl();

  void onServerStarted(HttpServer server) {
    var prefix = '';
    if (this.prefix case final p?) {
      prefix = '/$p';
    }

    final scheme = securityContext != null ? 'https' : 'http';

    print(
      'Serving at $scheme://${server.address.host}:${server.port}$prefix',
    );
  }

  Future<void> configureDependencies(covariant DI di) async {}

  /// Gzip compression of responses.
  ///
  /// On by default, and negotiated — only a client that sent
  /// `Accept-Encoding: gzip` ever receives a compressed response. Override
  /// with `const CompressionSettings.disabled()` when something in front of
  /// the server (a CDN, a reverse proxy) already compresses.
  CompressionSettings get compression => const CompressionSettings();

  /// Whether the server stops itself on `SIGTERM` / `SIGINT`.
  ///
  /// Container runtimes and process supervisors stop a process by sending
  /// `SIGTERM`, so without this a deploy or scale-down truncates whatever
  /// responses were mid-flight. Set to false to own signal handling yourself.
  bool get handleShutdownSignals => true;

  /// How long a shutdown waits for in-flight requests before giving up.
  ///
  /// Keep this below the grace period of whatever supervises the process —
  /// Kubernetes defaults to 30s before `SIGKILL`, and being killed part-way
  /// through the drain defeats the point.
  Duration get shutdownTimeout => const Duration(seconds: 15);

  /// Called once in-flight requests have drained, before the process exits.
  ///
  /// Release what the app owns here — database pools, message consumers,
  /// file handles. Throwing is logged and does not stop the shutdown.
  Future<void> onServerStopped() async {}

  /// Runs the async server startup sequence (bind, DI, routes, listen).
  ///
  /// The default implementation calls [start] as-is. Override to wrap [start]
  /// (for example with `runZoned` from `dart:async`) so that the entire startup
  /// runs inside a custom zone.
  Future<HttpServer> runStartup(Future<HttpServer> Function() start) => start();
}
