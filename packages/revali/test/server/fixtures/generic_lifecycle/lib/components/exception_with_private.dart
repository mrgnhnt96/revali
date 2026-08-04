import 'package:revali_router/revali_router.dart';

final class ExceptionWithPrivate implements LifecycleComponent {
  const ExceptionWithPrivate();

  ExceptionCatcherResult<MyException> handleException(MyException exception) {
    return _internal(exception);
  }

  ExceptionCatcherResult<MyException> _internal(MyException exception) {
    return const ExceptionCatcherResult.handled();
  }
}

final class MyException implements Exception {
  const MyException();
}
