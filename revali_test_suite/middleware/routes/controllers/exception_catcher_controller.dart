import 'package:middleware/components/lifecycle_components/exception_catcher.dart';
import 'package:revali_router/revali_router.dart';

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
    throw const ServerException({
      'message': 'Hello world!',
    });
  }

  @Catch()
  @Get('list')
  void handleList() {
    throw const ServerException([1, 2, 3]);
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
}
