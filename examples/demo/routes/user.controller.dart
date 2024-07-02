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
  User getNewPerson({
    @Query() required String name,
    @Param.pipe(StringToIntPipe) required int id,
  }) {
    final user = User(name, id);

    return user;
  }

  @Post('create')
  void create(
    @Query() String name,
  ) {}
}

class StringToIntPipe extends PipeTransform<String, int> {
  const StringToIntPipe(this.repo);

  final Repo repo;

  @override
  int transform(String value, ArgumentMetadata metadata) {
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
