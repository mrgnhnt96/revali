import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_shelf/converters/shelf_pipe.dart';

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
      pipe: pipe == null ? null : ShelfPipe.fromType(pipe),
    );
  }

  final List<String>? access;
  final ShelfPipe? pipe;
}
