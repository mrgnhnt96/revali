import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    required this.import,
  });

  factory ClientType.fromMeta(MetaType type) {
    return ClientType(
      name: type.name,
      import: ClientImports([if (type.importPath case final String path) path]),
    );
  }

  final String name;
  final ClientImports import;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
