import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

@AuthComponent()
@UserComponent()
// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('posts')
class PostsController {
  const PostsController();

  @Post()
  Future<String> handle({
    @Body(['data', 'input']) required CreatePostInput input,
    @Query('page') String? page,
  }) async {
    return input.title;
  }
}

class AuthComponent implements LifecycleComponent {
  const AuthComponent();

  MiddlewareResult middleware({
    @Cookie() required String auth,
  }) {
    return const MiddlewareResult.next();
  }
}

class UserComponent implements LifecycleComponent {
  const UserComponent();

  MiddlewareResult middleware({
    @Header() required String userId,
  }) {
    return const MiddlewareResult.next();
  }
}
