import 'package:middleware/components/lifecycle_components/pre_interceptor.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('pre/interceptor')
class PreInterceptorController {
  const PreInterceptorController();

  @AddData()
  @Get()
  String handle(@Data() String data) {
    return data;
  }

  @AddCustomData({'loz': 'oot'})
  @Get('custom-data')
  Map<String, dynamic> handleCustomData(@Data() Map<String, String> data) {
    return data;
  }
}
