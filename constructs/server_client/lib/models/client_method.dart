import 'package:revali_construct/revali_construct.dart';
import 'package:server_client/models/client_param.dart';
import 'package:server_client/models/client_return_type.dart';

// TODO: imports
class ClientMethod {
  const ClientMethod({
    required this.name,
    required this.parameters,
    required this.returnType,
  });

  factory ClientMethod.fromMeta(MetaMethod route) {
    return ClientMethod(
      name: route.name,
      returnType: ClientReturnType.fromMeta(route.returnType),
      parameters: route.params.map(ClientParam.fromMeta).toList(),
    );
  }

  final String name;
  final ClientReturnType returnType;
  final List<ClientParam> parameters;
}
