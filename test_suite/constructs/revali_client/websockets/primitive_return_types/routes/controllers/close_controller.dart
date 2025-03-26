import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('')
class CloseController {
  const CloseController();

  @WebSocket.mode(WebSocketMode.twoWay, triggerOnConnect: true)
  Stream<String> manually(CloseWebSocket closer) async* {
    yield 'Hello world!';

    closer.close();
  }
}
