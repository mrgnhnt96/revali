import 'package:revali_core/revali_core.dart' as core;
import 'package:revali_router/src/response/default_responses.dart';
import 'package:revali_router_core/revali_router_core.dart';

base class AppConfig extends core.AppConfig {
  const AppConfig({
    required super.host,
    required super.port,
    super.prefix,
  });

  const AppConfig.secure({
    required super.host,
    required super.port,
    required super.securityContext,
    super.requestClientCertificate,
    super.prefix,
  }) : super.secure();

  AppConfig.defaultApp() : super.defaultApp();

  DefaultResponses get defaultResponses => const DefaultResponses();

  /// Trusted proxy headers used when resolving [Request.ip].
  ///
  /// Override in your app class to supply proxy settings (for example after
  /// loading deployment config during [runStartup]).
  TrustedProxy get trustedProxy => const TrustedProxy();
}
