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
