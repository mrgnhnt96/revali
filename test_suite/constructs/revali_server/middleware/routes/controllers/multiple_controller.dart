import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/exception_catcher.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/guard.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/middleware.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/post_interceptor.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/pre_interceptor.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('multiple')
class MultipleController {
  const MultipleController();

  @Data()
  @AddHeader()
  @Catch()
  @Allow()
  @Continue(type: MiddlewareType.read)
  @Get('read')
  String readAuth(@Data() String auth) {
    return auth;
  }

  @LifecycleComponents([SomeLogger, AddData, AddHeader, Catch, Allow])
  @Get('type-reference')
  String typeReference() {
    return 'loz';
  }
}
