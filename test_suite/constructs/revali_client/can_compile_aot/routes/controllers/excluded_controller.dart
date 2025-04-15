import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@ExcludeFromClient()
@Controller('excluded')
class ExcludedController {
  const ExcludedController();

  @Get('user')
  Future<String> user() async {
    return 'Hello world!';
  }
}
