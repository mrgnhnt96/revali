part of 'router.dart';

/// The overrides a catcher, guard or middleware handed back.
typedef _ErrorOverrides = (int?, Map<String, String>?, Object?);

extension on _ErrorOverrides {
  /// Whether the application said anything at all about the response.
  ///
  /// A component that claims a failure without supplying a status, headers or
  /// a body has left the answer to the framework, which makes the result a
  /// fallback rather than something the app authored -- and fallbacks are the
  /// ones a released build replaces.
  bool get areAuthored => $1 != null || $2 != null || $3 != null;
}

extension OverrideResponse on Response {
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

    if (headers != null) {
      this.headers.addAll(headers);
    }

    if (!newBody.isNull) {
      this.body = newBody;
    }

    this.statusCode = statusCode ?? backupCode;
  }
}
