import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('shop/:shop-id')
class ShopController {
  const ShopController();

  @Get()
  String handle() {
    return 'Hello world!';
  }

  @Get('product/:product-id')
  String product() {
    return 'Hello product!';
  }
}
