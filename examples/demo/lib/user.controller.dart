import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

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
    @Query() required String name,
    @Param.pipe(StringToIntPipe) required int id,
  }) {
    return '$name $id';
  }

  // @Post('create')
  // void create() {}
}

class StringToIntPipe extends Pipe<String, int> {
  const StringToIntPipe();

  @override
  int transform(String value, PipeContext context) {
    return int.parse(value);
  }
}

class Auth extends Middleware {
  const Auth(this.type);

  final AuthType type;

  String get hi => 'hi';

  @override
  Future<MiddlewareResult> use(context, action) async {
    return action.next();
  }
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
