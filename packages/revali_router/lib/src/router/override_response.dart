part of 'router.dart';

extension OverrideResponse on MutableResponse {
  void _overrideWith({
    required int? statusCode,
    required int backupCode,
    required Map<String, String>? headers,
    required Object? body,
  }) {
    final _body = switch (body) {
      BodyData() => body,
      _ => BaseBodyData.from(body),
    };

    if (!_body.isNull) {
      this.body = _body;
    }

    this.statusCode = statusCode ?? backupCode;

    if (headers != null) {
      this.headers.addAll(headers);
    }
  }
}
