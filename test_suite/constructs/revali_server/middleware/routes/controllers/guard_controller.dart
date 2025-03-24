import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/components/lifecycle_components/guard.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('guard')
class GuardController {
  const GuardController();

  @Get('none')
  String handle() {
    return 'Hello world!';
  }

  @Allow()
  @Get('allow')
  String handleAllow() {
    return 'Hello world!';
  }

  @Reject()
  @Get('reject')
  String handleReject() {
    return 'Hello world!';
  }

  @Reject(statusCode: 419)
  @Get('reject-with-status')
  String handleRejectWithStatus() {
    return 'Hello world!';
  }
}
