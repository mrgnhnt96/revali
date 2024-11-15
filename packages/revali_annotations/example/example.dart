import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
