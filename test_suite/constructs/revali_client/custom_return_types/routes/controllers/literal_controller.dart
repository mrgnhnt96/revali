import 'package:revali_client_custom_return_types_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literal')
class LiteralController {
  const LiteralController();

  @Get('user')
  User user() {
    return const User(name: 'Hello world!');
  }

  @Get('list-of-users')
  List<User> listOfUsers() {
    return [const User(name: 'Hello world!')];
  }

  @Get('set-of-users')
  Set<User> setOfUsers() {
    return {const User(name: 'Hello world!')};
  }

  @Get('iterable-of-users')
  Iterable<User> iterableOfUsers() {
    return [const User(name: 'Hello world!')];
  }

  @Get('map-of-users')
  Map<String, User> mapOfUsers() {
    return {'user': const User(name: 'Hello world!')};
  }

  @Get('record-of-users')
  ({String name, User user}) recordOfUsers() {
    return (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }

  @Get('partial-record-of-users')
  (String name, {User user}) partialRecordOfUsers() {
    return ('Hello world!', user: const User(name: 'Hello world!'));
  }
}
