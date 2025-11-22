import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('expect-headers')
class ExpectHeadersController {
  const ExpectHeadersController();

  @ExpectHeaders({'X-My-Header'})
  @Get()
  String handle() {
    return 'Hello world!';
  }

  @ExpectHeaders({'X-My-Header', 'X-Another-Header'})
  @Get('many')
  String handleMany() {
    return 'Hello world!';
  }
}
