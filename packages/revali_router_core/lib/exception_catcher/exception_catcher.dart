import 'package:revali_router_core/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher_context.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher_result.dart';

abstract class ExceptionCatcher<T extends Exception> {
  const ExceptionCatcher();

  bool canCatch(Object exception) {
    // If T is Object then the ExceptionCatcher was not
    // supplied with a type argument
    // ignore: literal_only_boolean_expressions
    if ('$T' == '$Exception') {
      return false;
    }

    return exception is T;
  }

  ExceptionCatcherResult catchException(
    T exception,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  );
}
