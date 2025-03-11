import 'package:middleware/components/lifecycle_components/post_interceptor.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('post/interceptor')
class PostInterceptorController {
  const PostInterceptorController();

  @AddHeader()
  @Get()
  String handle() {
    return 'sup dude';
  }

  @AddCustomHeader(key: 'X-LOZ', value: 'oot')
  @Get('custom-header')
  String handleCustomHeader() {
    return 'sup dude';
  }
}
