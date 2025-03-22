import 'package:revali_router/revali_router.dart';
import 'package:revali_server_sse_custom_test/models/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literal')
class LiteralController {
  const LiteralController();

  @SSE('user')
  User handle() {
    return const User(name: 'Hello world!');
  }

  @SSE('list-of-users')
  List<User> listOfUsers() {
    return [const User(name: 'Hello world!')];
  }

  @SSE('set-of-users')
  Set<User> setOfUsers() {
    return {const User(name: 'Hello world!')};
  }

  @SSE('iterable-of-users')
  Iterable<User> iterableOfUsers() {
    return [const User(name: 'Hello world!')];
  }

  @SSE('map-of-users')
  Map<String, User> mapOfUsers() {
    return {'user': const User(name: 'Hello world!')};
  }

  @SSE('record-of-users')
  ({String name, User user}) recordOfUsers() {
    return (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }

  @SSE('partial-record-of-users')
  (String name, {User user}) partialRecordOfUsers() {
    return ('Hello world!', user: const User(name: 'Hello world!'));
  }
}
