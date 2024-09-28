import 'dart:io';

import 'package:hello/custom_params/get_user.dart';
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello(
    @Header.all(HttpHeaders.acceptHeader) List<String> accept,
  ) {
    return 'Hello, World! $accept';
  }

  @Get('sup')
  String hello2(
    @Bind(GetUser) User user,
  ) {
    return 'Hello, World!';
  }
}
