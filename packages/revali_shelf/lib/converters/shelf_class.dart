import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_param.dart';

class ShelfClass {
  const ShelfClass({
    required this.className,
    required this.params,
    required this.importPath,
  });

  factory ShelfClass.fromType(
    DartType type, {
    required Type superType,
  }) {
    final className = type.getDisplayString(withNullability: false);
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element',
      );
    }

    final superTypeWithoutGenertics = '$superType'.split('<').first;

    if (!element.allSupertypes.any((e) => e
        .getDisplayString(withNullability: false)
        .startsWith(superTypeWithoutGenertics))) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element that extends $superType',
      );
    }

    if (element.constructors.isEmpty) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element with a constructor',
      );
    }

    final constructor = element.constructors.first;

    final params = constructor.parameters.map((param) {
      return ShelfParam.fromElement(param);
    });

    final uri = element.librarySource.uri.toString();

    final imports = ShelfImports([uri]);

    return ShelfClass(
      className: className,
      params: params,
      importPath: imports,
    );
  }
  final String className;
  final Iterable<ShelfParam> params;
  final ShelfImports importPath;

  Iterable<String> get imports sync* {
    yield* importPath.imports;

    for (final param in params) {
      if (param.importPath case final imports?) yield* imports.imports;
    }
  }
}
