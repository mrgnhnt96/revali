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
    // TODO: Expect `data.input` and `data.email`, right now its only `data.input`
    @Body(['data', 'email']) required String email,
    @Body(['data', 'input']) required CreatePostInput input,
    @Query('page') String? page,
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
