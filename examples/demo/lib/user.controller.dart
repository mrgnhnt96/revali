import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_annotations/revali_annotations.dart';

@Auth(AuthType.user)
@Controller('user')
class ThisController {
  const ThisController(this.repo, this.logger);

  final Repo repo;
  final Logger logger;

  @Get()
  void listPeople() {}

  @Get(':id')
  String getNewPerson({
    @Query('name') required String name,
    @Param('id') required String id,
  }) {
    return '$name $id';
  }

  // @Post('create')
  // void create() {}
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
