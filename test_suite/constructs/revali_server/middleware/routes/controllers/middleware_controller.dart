import 'package:middleware/components/lifecycle_components/middleware.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('middleware')
class MiddlewareController {
  const MiddlewareController();

  @Continue(type: MiddlewareType.read)
  @Get('read')
  String readAuth(@Data() String auth) {
    return auth;
  }

  @Continue(type: MiddlewareType.write)
  @Get('write')
  String writeAuth(@Data() String auth) {
    return auth;
  }

  @ItsFine()
  @Get('its-fine')
  String itsFine(@Data() String value) {
    return value;
  }

  @Stop()
  @Get('stop')
  String stop() {
    return 'stop';
  }

  @Stop('please stop')
  @Get('please-stop')
  String pleaseStop() {
    return 'please stop';
  }
}
