import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';
import 'package:server_client_gen/models/client_param.dart';
import 'package:server_client_gen/models/client_return_type.dart';

class ClientMethod with ExtractImport {
  ClientMethod({
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

  @override
  List<ExtractImport?> get extractors => [returnType, ...parameters];

  @override
  List<ClientImports?> get imports => [];
}
