import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_param.dart';

class ShelfPipe {
  const ShelfPipe({
    required this.className,
    required this.params,
    required this.importPath,
  });

  factory ShelfPipe.fromType(DartType type) {
    final className = type.getDisplayString(withNullability: false);
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element',
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

    final pipeUri = element.librarySource.uri.toString();

    final imports = ShelfImports([pipeUri]);

    return ShelfPipe(
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
