import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/extract_import.dart';

/// A class that represents an annotation that will
/// be written exactly as it is in the source code.
class ServerMimic with ExtractImport {
  ServerMimic({
    required this.importPaths,
    required this.instance,
  });

  factory ServerMimic.fromDartObject(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final objectType = object.type;

    final typeImport = objectType?.element?.librarySource?.uri.toString();
    final importPaths = <String>{
      if (typeImport != null) typeImport,
    };

    if (object.type case final InterfaceType type?) {
      final constructorImports = type.constructors
          .map((e) => e.returnType.element.librarySource.uri.toString());

      importPaths.addAll(constructorImports);

      if (type.element case final ClassElement element) {
        for (final field in element.fields) {
          final fieldImport = field.type.element?.librarySource?.uri.toString();

          if (fieldImport != null) {
            importPaths.add(fieldImport);
          }
        }
      }
    }

    return ServerMimic(
      instance: annotation.toSource().replaceFirst('@', ''),
      importPaths: ServerImports(importPaths),
    );
  }

  final ServerImports importPaths;
  final String instance;

  @override
  List<ExtractImport?> get extractors => const [];

  @override
  List<ServerImports?> get imports => [importPaths];
}
