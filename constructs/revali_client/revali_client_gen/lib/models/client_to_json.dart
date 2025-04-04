import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/revali_construct.dart';

class ClientToJson {
  const ClientToJson({
    required this.returnType,
  });

  static ClientToJson? fromMeta(MetaToJson? meta) {
    if (meta == null) {
      return null;
    }

    return ClientToJson(returnType: ClientType.fromMeta(meta.returnType));
  }

  final ClientType returnType;
}
