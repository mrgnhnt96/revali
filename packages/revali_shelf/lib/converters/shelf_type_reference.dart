import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/converters/shelf_class.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfTypeReference with ExtractImport {
  ShelfTypeReference({
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
        types: const [],
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

  @override
  List<ExtractImport?> get extractors => [...types];

  @override
  List<ShelfImports?> get imports => const [];
}
