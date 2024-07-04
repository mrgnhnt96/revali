import 'package:revali_router/src/utils/override_error_response.dart';

final class GuardAction {
  const GuardAction();

  _Yes yes() => _Yes(this);

  /// {@macro override_error_response}
  _No no({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _No(
        this,
        statusCode: statusCode,
        headers: headers,
        body: body,
      );
}

sealed class GuardResult {
  const GuardResult();

  bool get isYes => this is _Yes;
  bool get isNo => this is _No;
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
