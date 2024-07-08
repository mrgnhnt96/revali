import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfTypesList {
  const ShelfTypesList({
    required this.types,
  });

  factory ShelfTypesList.fromElement(
    DartObject object, {
    required Type superType,
  }) {
    final catchersValue = object.getField('types')?.toListValue();

    if (catchersValue == null || catchersValue.isEmpty) {
      return ShelfTypesList(
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

    return ShelfTypesList(types: types);
  }

  final Iterable<ShelfClass> types;

  Iterable<String> get imports sync* {
    for (final catcher in types) {
      yield* catcher.importPath.imports;
    }
  }
}
