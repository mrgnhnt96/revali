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

  /// Takes [host] and [port] from the environment at startup.
  ///
  /// ```dart
  /// @App()
  /// final class MyApp extends AppConfig {
  ///   MyApp() : super.fromEnv();
  /// }
  /// ```
  ///
  /// Note this constructor is **not** `const` — it reads the process
  /// environment, which is only knowable at runtime — so the app class cannot
  /// have a `const` constructor either. That is the whole point: a container
  /// image is built once and told what it is by its environment, so a port
  /// baked in at compile time is a port that cannot be changed by the platform
  /// running it.
  ///
  /// Two defaults differ from [AppConfig.defaultApp] deliberately:
  ///
  /// - **Host is `0.0.0.0`, not `localhost`.** A server bound to `localhost`
  ///   inside a container accepts only connections originating in that same
  ///   container, so every request from outside is refused — with the process
  ///   looking perfectly healthy.
  /// - **Port comes from `PORT`.** Cloud Run, Heroku, Render and Fly all
  ///   assign a port this way and route to it; ignoring it means listening
  ///   where nothing is being sent.
  ///
  /// A `PORT` that is set but not a number throws rather than falling back:
  /// someone set it on purpose, and quietly listening somewhere else is worse
  /// than not starting.
  AppConfig.fromEnv({
    String hostVariable = 'HOST',
    String portVariable = 'PORT',
    String defaultHost = '0.0.0.0',
    int defaultPort = 8080,
    this.prefix = _defaultPrefix,
    this.workers = 1,
    this.backlog = 0,
    Env? env,
  })  : host = (env ?? Env.current).string(hostVariable, orElse: defaultHost),
        port = (env ?? Env.current).integer(portVariable, orElse: defaultPort),
        securityContext = null,
        requestClientCertificate = false,
        assert(workers >= 1, 'workers must be >= 1'),
        assert(backlog >= 0, 'backlog must be >= 0');

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

  /// Liveness and readiness probes.
  ///
  /// Served outside [prefix], on `/healthz` and `/readyz` by default. Override
  /// to register [HealthCheck]s, move the paths, or turn them off with
  /// `const HealthSettings.disabled()`.
  HealthSettings get health => const HealthSettings();

  /// The broker `@Consumes` handlers subscribe to.
  ///
  /// Returns null by default, which is what makes messaging opt-in: an app
  /// with no broker registers no consumers, even if handlers are annotated.
  /// Connecting is async, so this is a method rather than a getter.
  ///
  /// The returned broker is owned by the framework from here on — it is
  /// drained and closed as part of shutdown.
  Future<MessageBroker?> createBroker() async => null;

  /// Whether the server stops itself on `SIGTERM` / `SIGINT`.
  ///
  /// Container runtimes and process supervisors stop a process by sending
  /// `SIGTERM`, so without this a deploy or scale-down truncates whatever
  /// responses were mid-flight. Set to false to own signal handling yourself.
  bool get handleShutdownSignals => true;

  /// How long readiness reports 503 *before* the listener stops accepting.
  ///
  /// Closing the listening socket is invisible to a load balancer: it keeps
  /// routing until its own readiness probe fails, and those requests hit a
  /// closed socket. This delay is the window in which the probe can fail
  /// while the server is still able to serve, so traffic is steered away
  /// before the door shuts rather than after.
  ///
  /// Defaults to [Duration.zero], which preserves the previous behaviour of
  /// closing immediately. Behind a load balancer, set it to longer than the
  /// probe's period times its failure threshold — Kubernetes defaults to
  /// 10s × 3, so 30s or more is not unusual — and keep
  /// `drainDelay + shutdownTimeout` under the platform's kill grace period,
  /// which Kubernetes defaults to 30s.
  ///
  /// Only applied on `SIGTERM`. `SIGINT` is a human at a terminal who wants
  /// the process gone now, and making Ctrl-C wait would be a poor trade.
  Duration get drainDelay => Duration.zero;

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
