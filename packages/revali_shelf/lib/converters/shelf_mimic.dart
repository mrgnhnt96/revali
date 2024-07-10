import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/utils/extract_import.dart';

/// A class that represents an annotation that will
/// be written exactly as it is in the source code.
class ShelfMimic with ExtractImport {
  ShelfMimic({
    required this.importPaths,
    required this.instance,
  });

  static ShelfMimic fromDartObject(
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

    return ShelfMimic(
      instance: annotation.toSource().replaceFirst('@', ''),
      importPaths: ShelfImports(importPaths),
    );
  }

  final ShelfImports importPaths;
  final String instance;

  @override
  List<ExtractImport?> get extractors => const [];

  @override
  List<ShelfImports?> get imports => [importPaths];
}
