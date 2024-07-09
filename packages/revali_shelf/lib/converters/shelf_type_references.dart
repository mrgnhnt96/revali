import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfTypeReferences {
  const ShelfTypeReferences({
    required this.types,
  });

  factory ShelfTypeReferences.fromElement(
    DartObject object, {
    required Type superType,
  }) {
    final catchersValue = object.getField('types')?.toListValue();

    if (catchersValue == null || catchersValue.isEmpty) {
      return ShelfTypeReferences(
        types: [],
      );
    }

    final types = <ShelfClass>[];

    for (final catcher in catchersValue) {
      final type = catcher.toTypeValue();
      if (type == null) {
        throw ArgumentError('Invalid catcher type');
      }

      types.add(ShelfClass.fromType(type, superType: superType));
    }

    return ShelfTypeReferences(types: types);
  }

  final Iterable<ShelfClass> types;

  Iterable<String> get imports sync* {
    for (final catcher in types) {
      yield* catcher.importPath.imports;
    }
  }
}
