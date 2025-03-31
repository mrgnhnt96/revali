import 'package:revali_client_websocket_two_way_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('async')
class AsyncController {
  const AsyncController();

  @WebSocket('data-string')
  String dataString(
    @Body() String data,
    AsyncWebSocketSender<String> sender,
    CloseWebSocket close,
  ) {
    sender.send('Hello from the server');
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    });
    return data;
  }

  @WebSocket('stream-string')
  Stream<String> streamString(
    @Body() String data,
    AsyncWebSocketSender<Stream<String>> sender,
    CloseWebSocket close,
  ) async* {
    sender.send(Stream.value('Hello from the server'));
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    }).ignore();
    yield data;
  }

  @WebSocket('future-string')
  Future<String> futureString(
    @Body() String data,
    AsyncWebSocketSender<String> sender,
    CloseWebSocket close,
  ) async {
    sender.send('Hello from the server');
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    }).ignore();
    return data;
  }

  @WebSocket('user')
  User user(
    @Body() User data,
    AsyncWebSocketSender<User> sender,
    CloseWebSocket close,
  ) {
    sender.send(const User(name: 'Jane'));
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    });
    return data;
  }

  @WebSocket('stream-user')
  Stream<User> streamUser(
    @Body() User data,
    AsyncWebSocketSender<Stream<User>> sender,
    CloseWebSocket close,
  ) {
    sender.send(Stream.value(const User(name: 'Jane')));
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    });
    return Stream.value(data);
  }

  @WebSocket('future-user')
  Future<User> futureUser(
    @Body() User data,
    AsyncWebSocketSender<User> sender,
    CloseWebSocket close,
  ) async {
    sender.send(const User(name: 'Jane'));
    Future<void>.delayed(Duration.zero).then((_) {
      close();
    }).ignore();
    return data;
  }
}
