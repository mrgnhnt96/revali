import 'package:revali_router_core/error/override_error_response.dart';
import 'package:revali_router_core/error/override_error_response_mixin.dart';

sealed class ExceptionCatcherResult<T> {
  const ExceptionCatcherResult();

  const factory ExceptionCatcherResult.handled({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) = _Handled;

  const factory ExceptionCatcherResult.unhandled() = _Unhandled;

  bool get isHandled => this is _Handled;
  bool get isNotHandled => this is _Unhandled;

  // ignore: library_private_types_in_public_api
  _Handled<T> get asHandled => this as _Handled<T>;
}

/// {@template exception_catcher_handled}
/// Result of an exception catcher action that was handled.
///
/// {@macro override_error_response}
/// {@endtemplate}
final class _Handled<T> extends ExceptionCatcherResult<T>
    with OverrideErrorResponseMixin
    implements OverrideErrorResponse {
  const _Handled({
    this.body,
    this.headers,
    this.statusCode,
  });

  @override
  final int? statusCode;
  @override
  final Map<String, String>? headers;
  @override
  final Object? body;
}

final class _Unhandled<T> extends ExceptionCatcherResult<T> {
  const _Unhandled();
}
