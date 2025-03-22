import 'package:revali_router/revali_router.dart';
import 'package:revali_server_sse_custom_test/models/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @SSE('user')
  Stream<User> user() async* {
    yield const User(name: 'Hello world!');
    yield const User(name: 'Hello world!');
  }

  @SSE('list-of-users')
  Stream<List<User>> listOfUsers() async* {
    yield [const User(name: 'Hello world!')];
    yield [const User(name: 'Hello world!')];
  }

  @SSE('set-of-users')
  Stream<Set<User>> setOfUsers() async* {
    yield {const User(name: 'Hello world!')};
    yield {const User(name: 'Hello world!')};
  }

  @SSE('iterable-of-users')
  Stream<Iterable<User>> iterableOfUsers() async* {
    yield [const User(name: 'Hello world!')];
    yield [const User(name: 'Hello world!')];
  }

  @SSE('map-of-users')
  Stream<Map<String, User>> mapOfUsers() async* {
    yield {'user': const User(name: 'Hello world!')};
    yield {'user': const User(name: 'Hello world!')};
  }

  @SSE('record-of-users')
  Stream<({String name, User user})> recordOfUsers() async* {
    yield (name: 'Hello world!', user: const User(name: 'Hello world!'));
    yield (name: 'Hello world!', user: const User(name: 'Hello world!'));
  }

  @SSE('partial-record-of-users')
  Stream<(String name, {User user})> partialRecordOfUsers() async* {
    yield ('Hello world!', user: const User(name: 'Hello world!'));
    yield ('Hello world!', user: const User(name: 'Hello world!'));
  }
}
