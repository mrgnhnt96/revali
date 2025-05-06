import 'package:revali_client_cookies_test/components/add_cookies.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('cookies')
class CookiesController {
  const CookiesController();

  @Get('required')
  void get(@Cookie('X-Auth') String auth) {}

  @Get('optional')
  void getOptional(@Cookie('X-Auth') String? auth) {
    if (auth != null) {
      throw Exception('auth is not null');
    }
  }

  @AddCookies()
  @Get('lifecycle')
  void lifecycle() {}
}
