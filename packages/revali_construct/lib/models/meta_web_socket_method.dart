import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/web_socket_annotation.dart';

class MetaWebSocketMethod {
  MetaWebSocketMethod({
    required this.ping,
    required this.mode,
    required this.triggerOnConnect,
  });

  factory MetaWebSocketMethod.fromMeta(WebSocketAnnotation annotation) {
    return MetaWebSocketMethod(
      ping: annotation.ping,
      mode: annotation.mode,
      triggerOnConnect: annotation.triggerOnConnect,
    );
  }

  final Duration? ping;
  final WebSocketMode mode;
  final bool triggerOnConnect;
}
