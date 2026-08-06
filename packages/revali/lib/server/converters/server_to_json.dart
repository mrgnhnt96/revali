import 'package:revali/server/converters/server_type.dart';
import 'package:revali_construct/revali_construct.dart';

class ServerToJson {
  const ServerToJson({required this.returnType, required this.paramCount});

  static ServerToJson? fromMeta(MetaToJson? meta) {
    if (meta == null) {
      return null;
    }

    return ServerToJson(
      returnType: ServerType.fromMeta(meta.returnType),
      paramCount: meta.paramCount,
    );
  }

  final ServerType returnType;
  final int paramCount;
}
