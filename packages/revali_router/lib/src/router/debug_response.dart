part of 'router.dart';

extension DebugResponse on Router {
  ReadOnlyResponse _debugResponse(
    ReadOnlyResponse response, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!debug) {
      return response;
    }

    return response.debugBody(
      (body) => bodyForError(
        body,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

extension _ReadOnlyResponseX on ReadOnlyResponse {
  ReadOnlyResponse debugBody(
    Object? Function(ReadOnlyBody? body) body,
  ) {
    return SimpleResponse(
      statusCode,
      headers: headers.map((key, value) => MapEntry(key, value.join(','))),
      body: body(this.body),
    );
  }
}
