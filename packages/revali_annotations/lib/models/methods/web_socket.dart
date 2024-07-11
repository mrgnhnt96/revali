import 'package:revali_annotations/models/methods/method.dart';

final class WebSocket extends Method {
  const WebSocket(String? path)
      : ping = null,
        super('WS', path: path);
  const WebSocket.ping({String? path, required Duration this.ping})
      : super('WS', path: path);

  final Duration? ping;
}
