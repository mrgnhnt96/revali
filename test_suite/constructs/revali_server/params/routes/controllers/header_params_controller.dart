import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('required')
  String required(@Header('X-Shop-Id') String shopId) {
    return shopId;
  }

  @Get('optional')
  String optional(@Header('X-Shop-Id') String? shopId) {
    return shopId ?? 'no shop id';
  }

  @Get('all')
  String all(@Header.all('X-Shop-Id') List<String> shopIds) {
    return shopIds.join(',');
  }

  @Get('all-optional')
  String allOptional(@Header.all('X-Shop-Id') List<String>? shopIds) {
    return shopIds?.join(',') ?? 'no shop ids';
  }
}
