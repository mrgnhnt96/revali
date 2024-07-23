import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/web_socket_annotation.dart';

class MetaWebSocketMethod {
  MetaWebSocketMethod({
    required this.ping,
    required this.mode,
  });

  factory MetaWebSocketMethod.fromMeta(WebSocketAnnotation annotation) {
    return MetaWebSocketMethod(
      ping: annotation.ping,
      mode: annotation.mode,
    );
  }

  final Duration? ping;
  final WebSocketMode mode;
}
