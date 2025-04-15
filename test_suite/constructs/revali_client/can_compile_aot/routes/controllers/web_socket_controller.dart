import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('web-socket')
class WebSocketController {
  const WebSocketController();

  @ExcludeFromClient()
  @WebSocket('user')
  String user() {
    return 'Hello world!';
  }
}
