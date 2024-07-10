import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_pipe.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfBodyAnnotation with ExtractImport {
  ShelfBodyAnnotation({
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
      pipe: pipe == null ? null : ShelfPipe.fromType(pipe),
      acceptsNull: firstTypeArg == null
          ? null
          : firstTypeArg.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  final List<String>? access;
  final ShelfPipe? pipe;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ShelfImports?> get imports => const [];
}
