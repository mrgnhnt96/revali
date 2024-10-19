import 'package:revali_router_core/guard/guard_result.dart';

final class GuardAction {
  const GuardAction();

  // ignore: use_to_and_as_if_applicable
  GuardResult yes() => GuardResult.yes(this);

  /// {@macro override_error_response}
  GuardResult no({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) =>
      GuardResult.no(
        this,
        statusCode: statusCode,
        headers: headers,
        body: body,
      );
}
