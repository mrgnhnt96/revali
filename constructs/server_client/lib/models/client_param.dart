import 'package:revali_construct/revali_construct.dart';
import 'package:server_client/enums/parameter_position.dart';
import 'package:server_client/models/client_type.dart';

// TODO: imports
class ClientParam {
  const ClientParam({
    required this.name,
    required this.position,
    required this.type,
    required this.nullable,
  });

  factory ClientParam.fromMeta(MetaParam parameter) {
    return ClientParam(
      name: parameter.name,
      position: ParameterPosition.body,
      type: ClientType.fromMeta(parameter.type),
      nullable: parameter.nullable,
    );
  }

  final String name;
  final ClientType type;
  final ParameterPosition position;
  final bool nullable;
}
