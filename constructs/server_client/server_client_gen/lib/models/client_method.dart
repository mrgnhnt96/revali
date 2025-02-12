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
    required this.isSse,
    required this.isWebsocket,
    required this.path,
    required this.parentPath,
    required this.method,
  });

  factory ClientMethod.fromMeta(MetaMethod route, String parentPath) {
    return ClientMethod(
      name: route.name,
      parentPath: parentPath,
      method: route.method,
      returnType: ClientReturnType.fromMeta(route.returnType),
      parameters: route.params.map(ClientParam.fromMeta).toList(),
      isWebsocket: route.isWebSocket,
      isSse: route.isSse,
      path: route.path,
    );
  }

  final String name;
  final String? path;
  final String parentPath;
  final String? method;
  final ClientReturnType returnType;
  final List<ClientParam> parameters;
  final bool isWebsocket;
  final bool isSse;

  String get fullPath =>
      [parentPath, if (path case final String p) p].join('/');

  @override
  List<ExtractImport?> get extractors => [returnType, ...parameters];

  @override
  List<ClientImports?> get imports => [];
}
