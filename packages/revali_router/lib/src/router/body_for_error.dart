part of 'router.dart';

extension BodyForError on Router {
  ReadOnlyBody? bodyForError(
    ReadOnlyBody? body, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!debug) {
      return body;
    }

    final data = body?.data;
    final stackString = Trace.format(stackTrace).trim().split('\n');

    final newData = switch (data) {
      Map() => {
          ...data,
          'error': error.toString(),
          'stackTrace': stackString,
        },
      List() => [
          ...data,
          {
            'error': error.toString(),
            'stackTrace': stackString,
          },
        ],
      String() => '''$body

Error: $error

Stack Trace:
${stackString.join('\n')}''',
      Null() => {
          'error': error.toString(),
          'stackTrace': stackString,
        },
      _ => body,
    };

    return BaseBodyData.from(newData);
  }
}
