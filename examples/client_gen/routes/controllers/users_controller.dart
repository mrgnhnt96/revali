import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('users')
class UsersController {
  const UsersController();

  @Get()
  String simple() {
    return 'Hello world!';
  }

  @Get('profiles')
  List<User> users() {
    return [
      const User(name: 'Alice'),
    ];
  }

  @Get('me')
  User user() {
    return const User(name: 'Alice');
  }

  @Get('profiles-raw')
  List<NonGlobalUser> usersRaw() {
    return [
      const NonGlobalUser(name: 'Alice'),
    ];
  }
}

class NonGlobalUser {
  const NonGlobalUser({
    required this.name,
  });

  factory NonGlobalUser.fromJson(Map<String, dynamic> json) {
    return NonGlobalUser(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {};
  }

  final String name;
}
