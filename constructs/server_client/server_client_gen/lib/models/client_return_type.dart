import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/class_element_extensions.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';

class ClientReturnType with ExtractImport {
  ClientReturnType({
    required this.fullName,
    required this.resolvedName,
    required this.isStream,
    required this.import,
    required this.isPrimitive,
    required this.isIterable,
    required this.hasFromJson,
    required this.isVoid,
  });

  ClientReturnType.map()
      : fullName = 'Map<String, dynamic>',
        resolvedName = 'Map<String, dynamic>',
        isVoid = false,
        isStream = false,
        isPrimitive = true,
        isIterable = false,
        hasFromJson = false,
        import = ClientImports([]);

  factory ClientReturnType.fromMeta(MetaReturnType type) {
    final import = ClientImports.fromElement(type.resolvedElement);

    if (import.paths.length == 1) {
      // ignore: avoid_print
      print('Warning: Return type cannot be imported: ${type.type}');
      return ClientReturnType.map();
    }
    return ClientReturnType(
      fullName: type.type,
      resolvedName: type.resolvedElement?.name ?? type.type,
      isStream: type.isStream,
      import: import,
      isPrimitive: type.isPrimitive,
      isIterable: type.isIterable,
      hasFromJson: type.resolvedElement?.hasFromJsonMember ?? false,
      isVoid: type.isVoid,
    );
  }

  final String fullName;
  final String resolvedName;
  final bool isStream;
  final ClientImports import;
  final bool isPrimitive;
  final bool isIterable;
  final bool hasFromJson;
  final bool isVoid;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
