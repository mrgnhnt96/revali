import 'package:hello/exception_catchers/my_exception_catcher.dart';
import 'package:revali_router/revali_router.dart';

@MyExceptionCatcher()
@App()
final class MyApp extends AppConfig {
  MyApp() : super(host: 'localhost', port: 8083);

  @override
  DefaultResponses get defaultResponses => DefaultResponses(
        internalServerError: SimpleResponse(
          500,
          body: 'Uh oh! Something went wrong!',
        ),
      );
}