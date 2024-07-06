import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A class that represents an annotation that will
/// be written exactly as it is in the source code.
class ShelfMimic {
  const ShelfMimic({
    required this.imports,
    required this.instance,
  });

  static ShelfMimic fromDartObject(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final objectType = object.type;

    final typeImport = objectType?.element?.librarySource?.uri.toString();
    final imports = <String>{
      if (typeImport != null) typeImport,
    };

    if (object.type case final InterfaceType type?) {
      final constructorImports = type.constructors
          .map((e) => e.returnType.element.librarySource.uri.toString());

      imports.addAll(constructorImports);

      if (type.element case final ClassElement element) {
        for (final field in element.fields) {
          final fieldImport = field.type.element?.librarySource?.uri.toString();

          if (fieldImport != null) {
            imports.add(fieldImport);
          }
        }
      }
    }

    return ShelfMimic(
      instance: annotation.toSource().replaceFirst('@', ''),
      imports: imports,
    );
  }

  final Iterable<String> imports;
  final String instance;
}
