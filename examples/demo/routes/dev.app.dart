import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';

@DumbExceptionCatcher()
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );

  @override
  void configureDependencies(DI di) {
    di
      ..registerLazySingleton(Repo.new)
      ..registerLazySingleton(Logger.new);
  }
}

class DumbExceptionCatcher extends ExceptionCatcher<DumbException> {
  const DumbExceptionCatcher();

  @override
  ExceptionCatcherResult catchException(exception, context, action) {
    return action.handled();
  }
}

class DumbException implements Exception {}
