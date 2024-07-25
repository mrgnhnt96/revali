part of 'router.dart';

extension OverrideResponse on MutableResponse {
  void _overrideWith({
    required int? statusCode,
    required int backupCode,
    required Map<String, String>? headers,
    required Object? body,
  }) {
    final newBody = switch (body) {
      BodyData() => body,
      _ => BaseBodyData<dynamic>.from(body),
    };

    if (!newBody.isNull) {
      this.body = newBody;
    }

    this.statusCode = statusCode ?? backupCode;

    if (headers != null) {
      this.headers.addAll(headers);
    }
  }
}
