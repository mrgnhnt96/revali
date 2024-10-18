import 'package:revali_router/revali_router.dart';

@Controller('websocket')
class WebsocketController {
  const WebsocketController();

  @WebSocket('')
  String hello() {
    return 'Hello, World!';
  }
}
