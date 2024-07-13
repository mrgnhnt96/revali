import 'package:revali_router_core/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router_core/error/override_error_response.dart';
import 'package:revali_router_core/error/override_error_response_mixin.dart';

sealed class ExceptionCatcherResult {
  const ExceptionCatcherResult();

  const factory ExceptionCatcherResult.handled(
    ExceptionCatcherAction action, {
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) = _Handled;

  const factory ExceptionCatcherResult.notHandled(
    ExceptionCatcherAction action,
  ) = _NotHandled;

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

final class _NotHandled extends ExceptionCatcherResult {
  const _NotHandled(this.action);

  final ExceptionCatcherAction action;
}
