import 'package:revali_construct/revali_construct.dart';

// TODO: imports
class ClientReturnType {
  const ClientReturnType({
    required this.name,
    required this.isStream,
  });

  factory ClientReturnType.fromMeta(MetaReturnType type) {
    return ClientReturnType(
      name: type.type,
      isStream: type.isStream,
    );
  }

  final String name;
  final bool isStream;
}
