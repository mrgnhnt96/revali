import 'package:revali_core/revali_core.dart' as core;
import 'package:revali_router/src/response/default_responses.dart';

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

  DefaultResponses get defaultResponses => DefaultResponses();
}
