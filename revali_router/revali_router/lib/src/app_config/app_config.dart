import 'package:revali_core/revali_core.dart' as core;
import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/response/default_responses.dart';

base class AppConfig extends core.AppConfig {
  const AppConfig({
    required super.host,
    required super.port,
    super.prefix,
    super.workers,
    super.backlog,
  });

  const AppConfig.secure({
    required super.host,
    required super.port,
    required super.securityContext,
    super.requestClientCertificate,
    super.prefix,
    super.workers,
    super.backlog,
  }) : super.secure();

  AppConfig.defaultApp() : super.defaultApp();

  /// Takes [host] and [port] from the environment at startup.
  ///
  /// See `core.AppConfig.fromEnv`. Forwarded here because this is the class
  /// apps actually extend — `revali_router` re-exports `revali_core` with
  /// `AppConfig` hidden, so a constructor that exists only upstream is
  /// unreachable from an app.
  AppConfig.fromEnv({
    super.hostVariable,
    super.portVariable,
    super.defaultHost,
    super.defaultPort,
    super.prefix,
    super.workers,
    super.backlog,
    super.env,
  }) : super.fromEnv();

  DefaultResponses get defaultResponses => const DefaultResponses();

  /// Trusted proxy headers used when resolving [Request.ip].
  ///
  /// Override in your app class to supply proxy settings (for example after
  /// loading deployment config during [runStartup]).
  TrustedProxy get trustedProxy => const TrustedProxy();
}
