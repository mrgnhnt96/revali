import 'package:revali_router_core/exception_catcher/exception_catcher_result.dart';

final class ExceptionCatcherAction {
  const ExceptionCatcherAction();

  /// {@macro exception_catcher_handled}
  ExceptionCatcherResult handled({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      ExceptionCatcherResult.handled(
        this,
        body: body,
        headers: headers,
        statusCode: statusCode,
      );

  // ignore: use_to_and_as_if_applicable
  ExceptionCatcherResult notHandled() =>
      ExceptionCatcherResult.notHandled(this);
}
