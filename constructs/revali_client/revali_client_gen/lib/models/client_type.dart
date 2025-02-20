import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_construct/revali_construct.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    required this.import,
  });

  ClientType.map()
      : name = 'Map<String, dynamic>',
        import = ClientImports([]);

  factory ClientType.fromMeta(MetaType type) {
    final import =
        ClientImports([if (type.importPath case final String path) path]);

    if (import.packages.isEmpty && import.paths.isNotEmpty) {
      return ClientType.map();
    }

    return ClientType(
      name: type.name,
      import: import,
    );
  }

  factory ClientType.fromElement(ParameterElement element) {
    final import = ClientImports.fromElement(element.type.element);

    if (import.packages.isEmpty && import.paths.isNotEmpty) {
      return ClientType.map();
    }

    return ClientType(
      name: element.type.getDisplayString(),
      import: import,
    );
  }

  final String name;
  final ClientImports import;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
