import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('query')
class QueryParamsController {
  const QueryParamsController();

  @Get('required')
  String required([@Query() String shopId = '123']) {
    return shopId;
  }

  @Get('optional')
  String optional([@Query() String? shopId = '123']) {
    return shopId ?? 'no shop id';
  }

  @Get('all')
  String all([
    @Query.all('shopId') List<String> shopIds = const ['123', '456'],
  ]) {
    return shopIds.join(',');
  }

  @Get('all-optional')
  String allOptional([
    @Query.all('shopId') List<String>? shopIds = const ['123', '456'],
  ]) {
    return shopIds?.join(',') ?? 'no shop ids';
  }
}
