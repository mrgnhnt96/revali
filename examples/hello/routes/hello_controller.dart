import 'dart:io';

import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello(
    @Header.all(HttpHeaders.acceptHeader) List<String> contentType,
  ) {
    return 'Hello, World! $contentType';
  }

  @Get('sup')
  String hello2() {
    return 'Hello, World!';
  }
}
