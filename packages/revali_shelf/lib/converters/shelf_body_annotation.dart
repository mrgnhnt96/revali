import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_class.dart';

class ShelfBodyAnnotation {
  const ShelfBodyAnnotation({
    required this.access,
    required this.pipe,
    required this.acceptsNull,
  });

  factory ShelfBodyAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final access = object.getField('access')?.toListValue()?.map((e) {
      return e.toStringValue()!;
    }).toList();

    final pipe = object.getField('pipe')?.toTypeValue();

    final pipeSuper =
        (pipe?.element as ClassElement?)?.allSupertypes.firstWhere((element) {
      return element.element.name == 'Pipe';
    });

    final firstTypeArg = pipeSuper?.typeArguments.first;

    return ShelfBodyAnnotation(
      access: access,
      pipe: pipe == null ? null : ShelfClass.fromType(pipe, superType: Pipe),
      acceptsNull: firstTypeArg == null
          ? null
          : firstTypeArg.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  final List<String>? access;
  final ShelfClass? pipe;
  final bool? acceptsNull;
}
