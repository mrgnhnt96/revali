import 'package:revali_client_custom_return_types_test/enums/serialized_user_type.dart';
import 'package:revali_client_custom_return_types_test/enums/user_type.dart';
import 'package:revali_client_custom_return_types_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @Get('user')
  Stream<User> user() async* {
    yield const User(name: 'Hello world!');
  }

  @Get('list-of-users')
  Stream<List<User>> listOfUsers() async* {
    yield [const User(name: 'Hello world!')];
  }

  @Get('set-of-users')
  Stream<Set<User>> setOfUsers() async* {
    yield {const User(name: 'Hello world!')};
  }

  @Get('iterable-of-users')
  Stream<Iterable<User>> iterableOfUsers() async* {
    yield [const User(name: 'Hello world!')];
  }

  @Get('map-of-users')
  Stream<Map<String, User>> mapOfUsers() async* {
    yield {'user': const User(name: 'Hello world!')};
  }

  @Get('record-of-users')
  Stream<({String name, User user})> recordOfUsers() async* {
    yield (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }

  @Get('partial-record-of-users')
  Stream<(String name, {User user})> partialRecordOfUsers() async* {
    yield ('Hello world!', user: const User(name: 'Hello world!'));
  }

  @Get('user-type')
  Stream<UserType> userType() async* {
    yield UserType.admin;
  }

  @Get('serialized-user-type')
  Stream<SerializedUserType> serializedUserType() async* {
    yield SerializedUserType.admin;
  }
}
