import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/revali_construct.dart';

class ClientFromJson {
  const ClientFromJson({required this.params});

  static ClientFromJson? fromMeta(MetaFromJson? meta) {
    if (meta == null) {
      return null;
    }

    return ClientFromJson(
      params: meta.params.map(ClientType.fromMeta).toList(),
    );
  }

  final List<ClientType> params;
}
