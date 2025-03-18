import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('methods')
class MethodsController {
  const MethodsController();

  @Delete()
  String delete() {
    return 'Hello world!';
  }

  @Get()
  String get() {
    return 'Hello world!';
  }

  @Patch()
  String patch() {
    return 'Hello world!';
  }

  @Post()
  String post() {
    return 'Hello world!';
  }

  @Put()
  String put() {
    return 'Hello world!';
  }
}
