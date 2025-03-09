import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class Catch implements LifecycleComponent {
  const Catch();

  ExceptionCatcherResult<ServerException> exceptionCatcher(
    ServerException exception,
  ) {
    return ExceptionCatcherResult.handled(
      statusCode: 423,
      body: exception.message,
    );
  }
}

class ServerException implements Exception {
  const ServerException(this.message);

  final Object message;

  @override
  String toString() => '$message';
}
