import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('websocket/primitive')
class PrimitiveWebsocketController {
  const PrimitiveWebsocketController();

  @WebSocket('future-string')
  Future<String> futureString(@Body() String message) async {
    return message;
  }

  @WebSocket('string')
  String string(@Body() String message) {
    return message;
  }

  @WebSocket('stream-string')
  Stream<String> streamString(@Body() String message) async* {
    yield message;
  }
}
