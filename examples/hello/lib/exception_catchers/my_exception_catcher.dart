import 'dart:io';

import 'package:revali_router/revali_router.dart';

class MyException implements Exception {}

final class MyExceptionCatcher extends DefaultExceptionCatcher {
  const MyExceptionCatcher();

  @override
  ExceptionCatcherResult catchException(
    Exception exception,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  ) {
    return action.handled(
      statusCode: 500,
      headers: {
        HttpHeaders.contentTypeHeader: 'text/plain',
      },
      body: [
        'An error occurred',
      ],
    );
  }
}
