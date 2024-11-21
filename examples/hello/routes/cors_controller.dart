import 'package:revali_router/revali_router.dart';

@ExpectHeaders({'X-Some-Header'})
@AllowHeaders.simple()
@Controller('cors')
class CorsController {
  const CorsController();

  @Get()
  void headers() {}
}
