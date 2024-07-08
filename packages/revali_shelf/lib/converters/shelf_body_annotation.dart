import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfBodyAnnotation {
  const ShelfBodyAnnotation({
    this.access,
    this.pipe,
  });

  factory ShelfBodyAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final access = object.getField('access')?.toListValue()?.map((e) {
      return e.toStringValue()!;
    }).toList();

    final pipe = object.getField('pipe')?.toTypeValue();

    return ShelfBodyAnnotation(
      access: access,
      pipe: pipe == null ? null : ShelfClass.fromType(pipe, superType: Pipe),
    );
  }

  final List<String>? access;
  final ShelfClass? pipe;
}
