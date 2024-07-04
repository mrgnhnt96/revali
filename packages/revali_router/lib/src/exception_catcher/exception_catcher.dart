import 'package:revali_router/src/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context.dart';

abstract class ExceptionCatcher<T> {
  const ExceptionCatcher();

  bool canCatch(Object exception) {
    return exception is T;
  }

  ExceptionCatcherResult catchException(
    T exception,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  );
}
