import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfTypeReference {
  const ShelfTypeReference({
    required this.types,
  });

  factory ShelfTypeReference.fromElement(
    DartObject object, {
    required Type superType,
    String key = 'types',
  }) {
    final typesValue = object.getField(key)?.toListValue();

    if (typesValue == null || typesValue.isEmpty) {
      return ShelfTypeReference(
        types: [],
      );
    }

    final types = <ShelfClass>[];

    for (final typeValue in typesValue) {
      final type = typeValue.toTypeValue();
      if (type == null) {
        throw ArgumentError('Invalid type');
      }

      types.add(ShelfClass.fromType(type, superType: superType));
    }

    return ShelfTypeReference(types: types);
  }

  final Iterable<ShelfClass> types;

  Iterable<String> get imports sync* {
    for (final type in types) {
      yield* type.importPath.imports;
    }
  }
}
