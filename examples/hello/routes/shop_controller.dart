import 'package:revali_router/revali_router.dart';

@Controller('shop/:shopId')
class ShopController {
  const ShopController();

  @Get(':productId')
  String getProduct(
    @Param() String shopId,
    @Param() String productId,
    @Query('ids') String? ids,
  ) {
    return 'Shop ID: $shopId, Product ID: $productId, IDs: $ids';
  }
}
