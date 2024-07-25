import 'package:revali_router_core/error/override_error_response.dart';
import 'package:revali_router_core/error/override_error_response_mixin.dart';
import 'package:revali_router_core/guard/guard_action.dart';

sealed class GuardResult {
  const GuardResult();

  const factory GuardResult.yes(GuardAction action) = _Yes;
  const factory GuardResult.no(
    GuardAction action, {
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) = _No;

  bool get isYes => this is _Yes;
  bool get isNo => this is _No;
  // ignore: library_private_types_in_public_api
  _No get asNo => this as _No;
}

final class _Yes extends GuardResult {
  const _Yes(this.action);

  final GuardAction action;
}

final class _No extends GuardResult
    with OverrideErrorResponseMixin
    implements OverrideErrorResponse {
  const _No(
    this.action, {
    this.statusCode,
    this.headers,
    this.body,
  });

  final GuardAction action;
  @override
  final int? statusCode;
  @override
  final Map<String, String>? headers;
  @override
  final Object? body;
}
