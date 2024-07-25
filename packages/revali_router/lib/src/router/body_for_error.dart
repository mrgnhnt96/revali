part of 'router.dart';

ReadOnlyBody? bodyForError(
  ReadOnlyBody? body, {
  required Object error,
  required StackTrace stackTrace,
}) {
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
    String() => '''
$body

Error: $error

Stack Trace:
${stackString.join('\n')}''',
    Null() => {
        'error': error.toString(),
        'stackTrace': stackString,
      },
    _ => body,
  };

  return BaseBodyData<dynamic>.from(newData);
}
