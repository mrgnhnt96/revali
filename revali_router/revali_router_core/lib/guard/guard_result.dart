import 'package:revali_router_core/error/override_error_response.dart';
import 'package:revali_router_core/error/override_error_response_mixin.dart';

sealed class GuardResult {
  const GuardResult();

  const factory GuardResult.pass() = _Pass;
  const factory GuardResult.block({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) = _Block;

  bool get isPass => this is _Pass;
  bool get isBlock => this is _Block;
  // ignore: library_private_types_in_public_api
  _Block get asBlock => this as _Block;
}

final class _Pass extends GuardResult {
  const _Pass();
}

final class _Block extends GuardResult
    with OverrideErrorResponseMixin
    implements OverrideErrorResponse {
  const _Block({
    this.statusCode,
    this.headers,
    this.body,
  });

  @override
  final int? statusCode;
  @override
  final Map<String, String>? headers;
  @override
  final Object? body;
}
