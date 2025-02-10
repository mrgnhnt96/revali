import 'package:revali_construct/revali_construct.dart';

// TODO: imports
class ClientType {
  const ClientType({
    required this.name,
  });

  factory ClientType.fromMeta(MetaType type) {
    return ClientType(
      name: type.name,
    );
  }

  final String name;
}
