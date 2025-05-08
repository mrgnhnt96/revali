import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('query')
class QueryParamsController {
  const QueryParamsController();

  @Get('required/string')
  String requiredString(@Query() String shopId) {
    return shopId;
  }

  @Get('required/int')
  int requiredInt(@Query() int shopId) {
    return shopId;
  }

  @Get('required/bool')
  bool requiredBool({@Query() required bool shopId}) {
    return shopId;
  }

  @Get('required/double')
  double requiredDouble({@Query() required double shopId}) {
    return shopId;
  }

  @Get('optional/string')
  String optionalString(@Query() String? shopId) {
    return shopId ?? 'no shop id';
  }

  @Get('optional/int')
  int optionalInt(@Query() int? shopId) {
    return shopId ?? 0;
  }

  @Get('optional/bool')
  bool optionalBool({@Query() bool? shopId}) {
    return shopId ?? false;
  }

  @Get('optional/double')
  double optionalDouble(@Query() double? shopId) {
    return shopId ?? 0.0;
  }

  @Get('all/string')
  String allString(@Query.all('shopId') List<String> shopIds) {
    return shopIds.join(',');
  }

  @Get('all/int')
  String allInt(@Query.all('shopId') List<int> shopIds) {
    // hack to bypass bytes response
    return shopIds.join(',');
  }

  @Get('all/bool')
  List<bool> allBool(@Query.all('shopId') List<bool> shopIds) {
    return shopIds;
  }

  @Get('all/double')
  List<double> allDouble(@Query.all('shopId') List<double> shopIds) {
    return shopIds;
  }

  @Get('all-optional/string')
  List<String> allOptionalString(@Query.all('shopId') List<String>? shopIds) {
    return shopIds ?? [];
  }

  @Get('all-optional/int')
  String allOptionalInt(@Query.all('shopId') List<int>? shopIds) {
    // hack to bypass bytes response
    return shopIds?.join(',') ?? '';
  }

  @Get('all-optional/bool')
  List<bool> allOptionalBool(@Query.all('shopId') List<bool>? shopIds) {
    return shopIds ?? [];
  }

  @Get('all-optional/double')
  List<double> allOptionalDouble(@Query.all('shopId') List<double>? shopIds) {
    return shopIds ?? [];
  }
}
