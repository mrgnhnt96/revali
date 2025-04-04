import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('shop/:shopId')
class PathParamsController {
  const PathParamsController();

  @Get()
  String fromController(@Param() String shopId) {
    return shopId;
  }

  @Get('product/:productId')
  String fromMethod(@Param('productId') String id) {
    return id;
  }

  @Get('product/:productId/variant/:variantId')
  Map<String, String> fromMethodWithMultipleParams({
    @Param() required String shopId,
    @Param() required String productId,
    @Param() required String variantId,
  }) {
    return {
      'shopId': shopId,
      'productId': productId,
      'variantId': variantId,
    };
  }
}
