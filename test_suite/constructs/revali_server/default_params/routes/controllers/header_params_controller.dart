import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('required')
  String required([@Header('X-Shop-Id') String shopId = '123']) {
    return shopId;
  }

  @Get('optional')
  String optional([@Header('X-Shop-Id') String? shopId = '123']) {
    return shopId ?? 'no shop id';
  }

  @Get('all')
  String all([
    @Header.all('X-Shop-Id') List<String> shopIds = const ['123', '456'],
  ]) {
    return shopIds.join(',');
  }

  @Get('all-optional')
  String allOptional([
    @Header.all('X-Shop-Id') List<String>? shopIds = const ['123', '456'],
  ]) {
    return shopIds?.join(',') ?? 'no shop ids';
  }
}
