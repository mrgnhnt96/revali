import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

@Auth()
@User()
// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('posts')
class PostsController {
  const PostsController();

  @Post()
  String handle({
    @Body() required CreatePostInput input,
  }) {
    return 'Hello world!';
  }
}

class Auth implements LifecycleComponent {
  const Auth();

  MiddlewareResult middleware({
    @Cookie() required String auth,
  }) {
    return const MiddlewareResult.next();
  }
}

class User implements LifecycleComponent {
  const User();

  MiddlewareResult middleware({
    @Header() required String userId,
  }) {
    return const MiddlewareResult.next();
  }
}
