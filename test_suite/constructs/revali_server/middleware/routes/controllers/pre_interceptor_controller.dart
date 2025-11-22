import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/pre_interceptor.dart';
import 'package:revali_server_middleware_test/domain/auth_token.dart';
import 'package:revali_server_middleware_test/domain/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('pre/interceptor')
class PreInterceptorController {
  const PreInterceptorController();

  @AddToData()
  @Get()
  String handle(@Data() String data) {
    return data;
  }

  @AddToData()
  @Get('auth')
  String auth(@Data() AuthToken data) {
    return data.value;
  }

  @AddToData()
  @Get('auth-user')
  User authUser(@Data() User data) {
    return data;
  }

  @AddToData(addAuthToData: false)
  @Get('auth-user-throws')
  User authUserThrows(@Data() User data) {
    // never reached
    return data;
  }

  @AddToData()
  @Get('optional-user')
  User optionalUser(@Data() User? data) {
    return data!;
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
