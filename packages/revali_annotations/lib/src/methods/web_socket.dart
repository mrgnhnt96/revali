import 'package:revali_annotations/src/enums/web_socket_mode.dart';
import 'package:revali_annotations/src/methods/method.dart';

final class WebSocket extends Method {
  const WebSocket(
    String? path, {
    this.mode = WebSocketMode.twoWay,
    this.triggerOnConnect = false,
  })  : ping = null,
        super('WS', path: path);

  const WebSocket.mode(
    this.mode, {
    this.triggerOnConnect = false,
  })  : ping = null,
        super('WS', path: null);

  const WebSocket.ping({
    required Duration this.ping,
    String? path,
    this.mode = WebSocketMode.twoWay,
    this.triggerOnConnect = false,
  }) : super('WS', path: path);

  final Duration? ping;
  final WebSocketMode mode;
  final bool triggerOnConnect;
}
