import 'package:revali_client_websockets_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('websocket/custom')
class CustomWebsocketController {
  const CustomWebsocketController();

  @WebSocket('user')
  User user(@Body() User user) {
    return user;
  }

  @WebSocket('stream-user')
  Stream<User> streamUser(
    @Body(['user']) User user,
    @Body(['name']) String name,
  ) async* {
    yield user;
  }

  @WebSocket('future-user')
  Future<User> futureUser(@Body() User user) async {
    return user;
  }
}
