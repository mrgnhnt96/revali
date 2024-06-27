import 'package:zora_annotations/zora_annotations.dart';

import '../lib/repos/repo.dart';
import '../lib/utils/logger.dart';

@Auth(AuthType.user)
@Controller('user')
class ThisController {
  const ThisController(this.repo, this.logger);

  final Repo repo;
  final Logger logger;

  @Get('get')
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
