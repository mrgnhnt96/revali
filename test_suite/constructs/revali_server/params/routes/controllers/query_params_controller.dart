import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('query')
class QueryParamsController {
  const QueryParamsController();

  @Get('required')
  String required(@Query() String shopId) {
    return shopId;
  }

  @Get('optional')
  String optional(@Query() String? shopId) {
    return shopId ?? 'no shop id';
  }

  @Get('all')
  String all(@Query.all('shopId') List<String> shopIds) {
    return shopIds.join(',');
  }

  @Get('all-optional')
  String allOptional(@Query.all('shopId') List<String>? shopIds) {
    return shopIds?.join(',') ?? 'no shop ids';
  }

  /// Coerced query values (`?n=5` → int) must stringify for [String] params.
  @Get('coerced-string')
  String coercedString(@Query() String shopId) {
    return shopId;
  }

  /// Coerced ints must promote to [double] (`?n=5` → `5.0`).
  @Get('coerced-double')
  String coercedDouble(@Query() double n) {
    return '$n';
  }
}
