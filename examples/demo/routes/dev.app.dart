import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';

@AllowOrigins.all()
@DumbExceptionCatcher()
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..register(Repo.new)
      ..register(Logger.new);
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
