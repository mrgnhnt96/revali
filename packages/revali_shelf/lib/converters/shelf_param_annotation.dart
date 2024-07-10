import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_pipe.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfParamAnnotation with ExtractImport {
  ShelfParamAnnotation({
    required this.name,
    required this.pipe,
    required this.acceptsNull,
  });

  factory ShelfParamAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    final pipeSuper =
        (pipe?.element as ClassElement?)?.allSupertypes.firstWhere((element) {
      return element.element.name == 'Pipe';
    });

    final firstTypeArg = pipeSuper?.typeArguments.first;

    return ShelfParamAnnotation(
      name: name,
      pipe: pipe != null ? ShelfPipe.fromType(pipe) : null,
      acceptsNull: firstTypeArg == null
          ? null
          : firstTypeArg.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  final String? name;
  final ShelfPipe? pipe;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ShelfImports?> get imports => const [];
}
