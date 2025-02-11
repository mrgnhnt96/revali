import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';
import 'package:server_client_gen/models/client_type.dart';

class ClientParam with ExtractImport {
  ClientParam({
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

  @override
  List<ExtractImport?> get extractors => [type];

  @override
  List<ClientImports?> get imports => [];
}
