import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/revali_construct.dart';

class ClientRecordProp {
  const ClientRecordProp({
    required this.name,
    required this.isNamed,
    required this.type,
  });

  factory ClientRecordProp.fromMeta(MetaRecordProp prop) {
    return ClientRecordProp(
      name: prop.name,
      isNamed: prop.isNamed,
      type: ClientType.fromMeta(prop.type),
    );
  }

  final String? name;
  final bool isNamed;
  final ClientType type;

  bool get isPositioned => !isNamed;
}
