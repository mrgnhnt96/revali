import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/exception_catcher.dart';

@Controller('exception-catcher')
class ExceptionCatcherController {
  const ExceptionCatcherController();

  @Get('none')
  void none() {
    throw const ServerException('Hello world!');
  }

  @Catch()
  @Get('string')
  void handle() {
    throw const ServerException('Hello world!');
  }

  @Catch()
  @Get('map')
  void handleObject() {
    throw const ServerException({'message': 'Hello world!'});
  }

  @Catch()
  @Get('list')
  void handleList() {
    throw const ServerException(['a', 'b', 'c']);
  }

  @Catch()
  @Get('set')
  void handleSet() {
    throw const ServerException({'hello', 'world'});
  }

  @Catch()
  @Get('iterable')
  void handleIterable() {
    Iterable<String> get() sync* {
      yield 'Hello';
      yield 'world';
    }

    throw ServerException(get());
  }

  @Catch()
  @Get('bool')
  void handleBool() {
    throw const ServerException(true);
  }

  @Catch(423)
  @Get('status-code')
  void handleStatusCode() {
    throw const ServerException('Hello world!');
  }
}
