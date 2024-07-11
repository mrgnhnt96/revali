import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';

@DumbExceptionCatcher()
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );
}

class DumbExceptionCatcher extends ExceptionCatcher<DumbException> {
  const DumbExceptionCatcher();

  @override
  ExceptionCatcherResult catchException(exception, context, action) {
    return action.handled();
  }
}

class DumbException implements Exception {}
