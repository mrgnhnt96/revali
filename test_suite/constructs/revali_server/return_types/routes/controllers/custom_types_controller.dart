import 'package:revali_router/revali_router.dart';
import 'package:revali_server_return_types_test/models/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('custom/types')
class CustomTypesController {
  const CustomTypesController();

  @Get('user')
  User handle() {
    return const User(name: 'Hello world!');
  }

  @Get('future-user')
  Future<User> futureUser() async {
    return const User(name: 'Hello world!');
  }

  @Get('stream-user')
  Stream<User> streamUser() async* {
    yield const User(name: 'Hello world!');
  }

  @Get('list-of-users')
  List<User> listOfUsers() {
    return [const User(name: 'Hello world!')];
  }

  @Get('future-list-of-users')
  Future<List<User>> futureListOfUsers() async {
    return [const User(name: 'Hello world!')];
  }

  @Get('map-of-users')
  Map<String, User> mapOfUsers() {
    return {'user': const User(name: 'Hello world!')};
  }

  @Get('future-map-of-users')
  Future<Map<String, User>> futureMapOfUsers() async {
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

  @Get('future-record-of-users')
  Future<({String name, User user})> futureRecordOfUsers() async {
    return (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }
}
