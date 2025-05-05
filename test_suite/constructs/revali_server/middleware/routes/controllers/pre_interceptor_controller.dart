import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/pre_interceptor.dart';
import 'package:revali_server_middleware_test/domain/auth_token.dart';
import 'package:revali_server_middleware_test/domain/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('pre/interceptor')
class PreInterceptorController {
  const PreInterceptorController();

  @AddData()
  @Get()
  String handle(@Data() String data) {
    return data;
  }

  @AddData()
  @Get('auth')
  String auth(@Data() AuthToken data) {
    return data.value;
  }

  @AddData()
  @Get('auth-user')
  User authUser(@Data() User data) {
    return data;
  }

  @Get('logger')
  String logger(@Dep() Logger logger) {
    return 'logged';
  }

  @AddCustomData({'loz': 'oot'})
  @Get('custom-data')
  Map<String, dynamic> handleCustomData(@Data() Map<String, String> data) {
    return data;
  }
}
