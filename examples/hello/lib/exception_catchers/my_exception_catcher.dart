import 'dart:io';

import 'package:revali_router/revali_router.dart';

class MyException implements Exception {}

final class MyExceptionCatcher extends DefaultExceptionCatcher {
  const MyExceptionCatcher();

  @override
  ExceptionCatcherResult<Exception> catchException(
    Exception exception,
    Context context,
  ) {
    return const ExceptionCatcherResult.handled(
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
