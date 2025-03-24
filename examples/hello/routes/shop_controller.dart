import 'package:revali_router/revali_router.dart';

@Controller('shop/:shopId')
class ShopController {
  const ShopController();

  @Get(':productId')
  User getProduct(
    @Param() String shopId,
    @Param() String productId,
    @Query('ids') String? ids,
  ) {
    return const User();
  }
}

class User {
  const User();
}
