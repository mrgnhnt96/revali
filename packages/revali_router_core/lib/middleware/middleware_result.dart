import 'package:revali_router_core/error/override_error_response.dart';
import 'package:revali_router_core/error/override_error_response_mixin.dart';
import 'package:revali_router_core/middleware/middleware_action.dart';

sealed class MiddlewareResult {
  const MiddlewareResult();

  const factory MiddlewareResult.next(MiddlewareAction action) = _Next;
  const factory MiddlewareResult.stop(
    MiddlewareAction action, {
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) = _Stop;

  bool get isNext => this is _Next;
  bool get isStop => this is _Stop;
  // ignore: library_private_types_in_public_api
  _Stop get asStop => this as _Stop;
}

final class _Next extends MiddlewareResult {
  const _Next(this.action);

  final MiddlewareAction action;
}

final class _Stop extends MiddlewareResult
    with OverrideErrorResponseMixin
    implements OverrideErrorResponse {
  const _Stop(
    this.action, {
    this.body,
    this.headers,
    this.statusCode,
  });

  final MiddlewareAction action;

  @override
  final Object? body;

  @override
  final Map<String, String>? headers;

  @override
  final int? statusCode;
}
