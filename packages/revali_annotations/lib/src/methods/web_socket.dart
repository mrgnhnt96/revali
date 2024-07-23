import 'package:revali_annotations/src/enums/web_socket_mode.dart';
import 'package:revali_annotations/src/methods/method.dart';

final class WebSocket extends Method {
  const WebSocket(
    String? path, {
    this.mode = WebSocketMode.twoWay,
  })  : ping = null,
        super('WS', path: path);

  const WebSocket.ping({
    String? path,
    required Duration this.ping,
    this.mode = WebSocketMode.twoWay,
  }) : super('WS', path: path);

  final Duration? ping;
  final WebSocketMode mode;
}
