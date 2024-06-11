import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:zora_core/zora_core.dart';

@Auth()
@Request()
class ThisRequest {
  const ThisRequest(this.repo, this.logger);

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
  const Auth();
}

class User {
  const User(this.name);

  final String name;
}
