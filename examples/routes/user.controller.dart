import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:zora_core/zora_core.dart';

@Auth(AuthType.user)
@Controller('/user')
class ThisController {
  const ThisController(this.repo, this.logger);

  final Repo repo;
  final Logger logger;

  @Get()
  getNewPerson({
    @Query('name') required String name,
    @Param('age') int? age,
    required User user,
  }) {
    return null;
  }
}

class Auth extends Middleware {
  const Auth(this.type);

  AuthRepo get repo => get();

  final AuthType type;

  String get hi => 'hi';
}

enum AuthType {
  admin,
  user,
}

class AuthRepo {}

class User {
  const User(this.name);

  final String name;
}

class Lazy {
  Lazy();

  String? value;

  String get() {
    return value ??= 'lazy';
  }
}
