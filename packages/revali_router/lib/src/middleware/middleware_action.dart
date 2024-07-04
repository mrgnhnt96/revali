import 'package:revali_router/src/response/override_error_response.dart';

class MiddlewareResult {
  const MiddlewareResult();

  bool get isNext => this is _Next;
  bool get isStop => this is _Stop;
  _Stop get asStop => this as _Stop;
}

class _Next extends MiddlewareResult {
  const _Next(this.action);

  final MiddlewareAction action;
}

class _Stop extends MiddlewareResult
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

class MiddlewareAction {
  const MiddlewareAction();

  _Next next() => _Next(this);

  /// {@macro override_error_response}
  _Stop stop({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _Stop(
        this,
        statusCode: statusCode,
        headers: headers,
        body: body,
      );
}
