import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfParamAnnotation {
  const ShelfParamAnnotation({
    required this.name,
    required this.pipe,
  });

  factory ShelfParamAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    return ShelfParamAnnotation(
      name: name,
      pipe: pipe != null ? ShelfClass.fromType(pipe) : null,
    );
  }

  final String? name;
  final ShelfClass? pipe;
}
