import 'package:meta/meta.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher_context.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher_result.dart';

abstract base class ExceptionCatcher<T extends Exception> {
  const ExceptionCatcher();

  @nonVirtual
  bool canCatch(Object exception) {
    // If T is `Exception` then the ExceptionCatcher was not
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
  );
}

abstract base class DefaultExceptionCatcher
    implements ExceptionCatcher<Exception> {
  const DefaultExceptionCatcher();

  @override
  bool canCatch(_) => true;
}
