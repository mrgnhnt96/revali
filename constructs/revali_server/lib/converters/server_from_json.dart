import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_type.dart';

class ServerFromJson {
  const ServerFromJson({required this.params});

  static ServerFromJson? fromMeta(MetaFromJson? meta) {
    if (meta == null) {
      return null;
    }

    return ServerFromJson(
      params: meta.params.map(ServerType.fromMeta).toList(),
    );
  }

  final List<ServerType> params;
}
