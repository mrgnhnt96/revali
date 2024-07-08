import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfQueryAnnotation {
  const ShelfQueryAnnotation({
    required this.name,
    required this.pipe,
    required this.all,
  });

  factory ShelfQueryAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();
    final all = object.getField('all')?.toBoolValue() ?? false;

    return ShelfQueryAnnotation(
      name: name,
      pipe: pipe != null ? ShelfClass.fromType(pipe, superType: Pipe) : null,
      all: all,
    );
  }

  final String? name;
  final ShelfClass? pipe;
  final bool all;
}
