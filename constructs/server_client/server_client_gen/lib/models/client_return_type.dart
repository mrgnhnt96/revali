import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';

class ClientReturnType with ExtractImport {
  ClientReturnType({
    required this.name,
    required this.isStream,
    required this.import,
  });

  ClientReturnType.map()
      : name = 'Map<String, dynamic>',
        isStream = false,
        import = ClientImports([]);

  factory ClientReturnType.fromMeta(MetaReturnType type) {
    final import = ClientImports.fromElement(type.resolvedElement);

    if (import.paths.length == 1) {
      // ignore: avoid_print
      print('Warning: Return type cannot be imported: ${type.type}');
      return ClientReturnType.map();
    }
    return ClientReturnType(
      name: type.type,
      isStream: type.isStream,
      import: import,
    );
  }

  final String name;
  final bool isStream;
  final ClientImports import;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
