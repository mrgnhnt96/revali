import 'package:revali_router/src/response/override_error_response.dart';

final class ExceptionCatcherAction {
  const ExceptionCatcherAction();

  /// {@macro exception_catcher_handled}
  _Handled handled({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _Handled(
        this,
        body: body,
        headers: headers,
        statusCode: statusCode,
      );

  _NotHandled notHandled() => _NotHandled(this);
}

sealed class ExceptionCatcherResult {
  const ExceptionCatcherResult();

  bool get isHandled => this is _Handled;
  bool get isNotHandled => this is _NotHandled;

  _Handled get asHandled => this as _Handled;
}

/// {@template exception_catcher_handled}
/// Result of an exception catcher action that was handled.
///
/// {@macro override_error_response}
/// {@endtemplate}
final class _Handled extends ExceptionCatcherResult
    with OverrideErrorResponseMixin
    implements OverrideErrorResponse {
  const _Handled(
    this.action, {
    this.body,
    this.headers,
    this.statusCode,
  });

  final int? statusCode;
  final Map<String, String>? headers;
  final Object? body;

  final ExceptionCatcherAction action;
}

final class _NotHandled {
  const _NotHandled(this.action);

  final ExceptionCatcherAction action;
}
