import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@PreventHeaders({'X-Parent-Header'})
@Controller('prevent-headers')
class PreventHeadersController {
  const PreventHeadersController();

  @Get('inherited')
  String inherited() {
    return 'Hello world!';
  }

  @PreventHeaders.noInherit({'X-My-Header'})
  @Get('not-inherited')
  String handleMany() {
    return 'Hello world!';
  }

  @PreventHeaders({'X-My-Header'})
  @Get('combined')
  String combined() {
    return 'Hello world!';
  }
}
