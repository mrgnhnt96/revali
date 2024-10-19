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
        '__DEBUG__': {
          'error': error.toString(),
          'stackTrace': stackString,
        },
      },
    List() => [
        ...data,
        {
          '__DEBUG__': {
            'error': error.toString(),
            'stackTrace': stackString,
          },
        },
      ],
    String() => '''
$body

__DEBUG__:
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
