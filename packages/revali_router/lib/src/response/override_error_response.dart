/// {@template override_error_response}
/// [body], [headers], and [statusCode] are optional, if any of them are set, they will
/// be used to **override** the response body, headers, or statusCode.
/// {@endtemplate}
abstract class OverrideErrorResponse {
  const OverrideErrorResponse();

  Map<String, String>? get headers;
  int? get statusCode;
  Object? get body;
}

mixin OverrideErrorResponseMixin {
  Map<String, String>? get headers;
  int? get statusCode;
  Object? get body;

  (int?, Map<String, String>?, Object?) getResponseOverrides() {
    final body = this.body;
    final headers = this.headers;
    final statusCode = this.statusCode;

    return (statusCode, headers, body);
  }
}
