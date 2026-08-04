import 'package:revali/server/converters/server_type.dart';
import 'package:revali_construct/revali_construct.dart';

class ServerToJson {
  const ServerToJson({required this.returnType});

  static ServerToJson? fromMeta(MetaToJson? meta) {
    if (meta == null) {
      return null;
    }

    return ServerToJson(returnType: ServerType.fromMeta(meta.returnType));
  }

  final ServerType returnType;
}
