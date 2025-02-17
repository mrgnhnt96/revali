import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

@AuthComponent()
@UserComponent()
// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('posts')
class PostsController {
  const PostsController();

  @Post()
  String handle({
    // TODO: Expect `data.input` and `data.email`, right now its only `data.input`
    // @Body(['data', 'email']) required String email,
    @Body(['data', 'input']) required CreatePostInput input,
    @Query('page') String? page,
  }) {
    return input.title;
  }

  // todo: what happens when the input is scoped to the server?
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
