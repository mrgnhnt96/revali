import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@AllowOrigins({'https://zelda.com'})
@Controller('allow-origin')
class AllowOriginController {
  const AllowOriginController();

  @AllowOrigins.all()
  @Get('all')
  String all() {
    return 'Hello world!';
  }

  @Get('inherited')
  String inherited() {
    return 'Hello world!';
  }

  @AllowOrigins.noInherit({'https://link.com'})
  @Get('not-inherited')
  String handleMany() {
    return 'Hello world!';
  }

  @AllowOrigins({'https://link.com'})
  @Get('combined')
  String combined() {
    return 'Hello world!';
  }
}
