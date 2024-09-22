import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
