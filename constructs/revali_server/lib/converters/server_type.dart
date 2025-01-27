import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/class_element_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerType with ExtractImport {
  ServerType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.importPath,
  });

  factory ServerType.fromMeta(MetaType type) {
    return ServerType(
      name: type.name,
      hasFromJsonConstructor: type.hasFromJsonConstructor,
      importPath: ServerImports([
        if (type.importPath case final String path) path,
      ]),
    );
  }

  factory ServerType.fromElement(ParameterElement element) {
    final name = element.type.getDisplayString();
    final hasFromJsonConstructor = switch (element.type.element) {
      final ClassElement element => element.hasFromJsonMember,
      _ => false,
    };

    final importPath = switch (hasFromJsonConstructor) {
      false => null,
      true => ServerImports.fromElement(element),
    };

    return ServerType(
      name: name,
      hasFromJsonConstructor: hasFromJsonConstructor,
      importPath: importPath,
    );
  }

  final String name;
  final bool hasFromJsonConstructor;
  final ServerImports? importPath;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ServerImports?> get imports => [importPath];
}
