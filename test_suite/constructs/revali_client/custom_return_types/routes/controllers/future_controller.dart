import 'package:revali_client_custom_return_types_test/enums/serialized_user_type.dart';
import 'package:revali_client_custom_return_types_test/enums/user_type.dart';
import 'package:revali_client_custom_return_types_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future')
class FutureController {
  const FutureController();

  @Get('user')
  Future<User> user() async {
    return const User(name: 'Hello world!');
  }

  @Get('list-of-users')
  Future<List<User>> listOfUsers() async {
    return [const User(name: 'Hello world!')];
  }

  @Get('set-of-users')
  Future<Set<User>> setOfUsers() async {
    return {const User(name: 'Hello world!')};
  }

  @Get('iterable-of-users')
  Future<Iterable<User>> iterableOfUsers() async {
    return [const User(name: 'Hello world!')];
  }

  @Get('map-of-users')
  Future<Map<String, User>> mapOfUsers() async {
    return {'user': const User(name: 'Hello world!')};
  }

  @Get('record-of-users')
  Future<({String name, User user})> recordOfUsers() async {
    return (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }

  @Get('partial-record-of-users')
  Future<(String name, {User user})> partialRecordOfUsers() async {
    return ('Hello world!', user: const User(name: 'Hello world!'));
  }

  @Get('user-type')
  Future<UserType> userType() async {
    return UserType.admin;
  }

  @Get('serialized-user-type')
  Future<SerializedUserType> serializedUserType() async {
    return SerializedUserType.admin;
  }
}
