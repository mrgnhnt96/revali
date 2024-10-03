import 'dart:io';

import 'package:hello/custom_params/get_user.dart';
import 'package:hello/exception_catchers/my_exception_catcher.dart';
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello(
    @Header.all(HttpHeaders.acceptHeader) List<String> accept,
  ) {
    throw MyException();
    return 'Hello, World! $accept';
  }

  @Get('sup')
  String hello2(
    @Binds(GetUser) User user,
  ) {
    return 'Hello, World!';
  }
}
