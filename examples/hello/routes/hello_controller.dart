import 'dart:io';

import 'package:hello/combines/auth_components.dart';
import 'package:hello/custom_params/get_user.dart';
import 'package:revali_router/revali_router.dart';

@Combines([AuthComponents])
@Controller('hello')
class HelloController {
  @Get()
  String hello(
    @Header.all(HttpHeaders.acceptHeader) List<String> accept,
  ) {
    return 'Hello, World! $accept';
  }

  @Get('sup')
  @MyResponseHandler()
  String hello2(
    @Data() User? user,
  ) {
    return 'Hello, World!';
  }

  @Get('new')
  @Redirect('sup')
  void newHello() {
    print('Redirecting');
  }
}

class MyResponseHandler implements ResponseHandler {
  const MyResponseHandler();

  @override
  Future<void> handle(
    Response response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {}
}
