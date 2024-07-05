import 'package:examples/repos/repo.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Auth(AuthType.user)
@Controller('user')
class ThisController {
  const ThisController();

  // final Repo repo;
  // final Logger logger;

  @Get()
  Future<void> listPeople() async {}

  @Catches([
    NotAuthCatcher('hi'),
  ])
  @NotAuthCatcher('bye')
  @Get(':id')
  User getNewPerson({
    @Query.pipe(NamePipe) required String name,
    @Param.pipe(StringToIntPipe) required int id,
    @Body(['name']) String? data,
  }) {
    final user = User(name, id);

    return user;
  }

  @Post('create')
  void create(
    @Query() String name,
  ) {}
}

class NamePipe extends Pipe<String, String> {
  const NamePipe();

  @override
  String transform(value, context) {
    return 'value: $value';
  }
}

class StringToIntPipe extends Pipe<String, int> {
  const StringToIntPipe(this.repo);

  final Repo repo;

  @override
  int transform(value, context) {
    return int.parse(value);
  }
}

class User {
  const User(this.name, this.id);

  final String name;
  final int id;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
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

class Guard {
  const Guard(this.types);

  final List<Type> types;
}

enum AuthType {
  admin,
  user,
}

class AuthRepo {}

class Lazy {
  Lazy();

  String? value;

  String get() {
    return value ??= 'lazy';
  }
}

class NotAuth implements Exception {}

class NotAuthCatcher extends ExceptionCatcher {
  const NotAuthCatcher(this.value);

  final String value;

  @override
  ExceptionCatcherResult catchException(exception, context, action) {
    return action.handled();
  }
}
