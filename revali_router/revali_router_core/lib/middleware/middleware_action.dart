import 'package:revali_router_core/middleware/middleware_result.dart';

class MiddlewareAction {
  const MiddlewareAction();

  // ignore: use_to_and_as_if_applicable
  MiddlewareResult next() => MiddlewareResult.next(this);

  /// {@macro override_error_response}
  MiddlewareResult stop({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      MiddlewareResult.stop(
        this,
        statusCode: statusCode,
        headers: headers,
        body: body,
      );
}
