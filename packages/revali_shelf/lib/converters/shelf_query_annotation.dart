import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfQueryAnnotation {
  const ShelfQueryAnnotation({
    required this.name,
    required this.pipe,
  });

  factory ShelfQueryAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    return ShelfQueryAnnotation(
      name: name,
      pipe: pipe != null ? ShelfClass.fromType(pipe) : null,
    );
  }

  final String? name;
  final ShelfClass? pipe;
}
