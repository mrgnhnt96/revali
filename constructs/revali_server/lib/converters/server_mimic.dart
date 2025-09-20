import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/extract_import.dart';

/// A class that represents an annotation that will
/// be written exactly as it is in the source code.
class ServerMimic with ExtractImport {
  ServerMimic({required this.importPaths, required this.instance});

  factory ServerMimic.fromDartObject(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final objectType = object.type;

    final importableElements = <Element?>[objectType?.element];

    if (object.type case final InterfaceType type?) {
      importableElements.addAll(
        type.constructors.map((e) => e.returnType.element),
      );

      if (type.element case final ClassElement element) {
        for (final field in element.fields) {
          importableElements.add(field.type.element);
        }
      }
    }

    return ServerMimic(
      instance: annotation.toSource().replaceFirst('@', ''),
      importPaths: ServerImports.fromElements(importableElements),
    );
  }

  final ServerImports importPaths;
  final String instance;

  @override
  List<ExtractImport?> get extractors => const [];

  @override
  List<ServerImports?> get imports => [importPaths];
}
