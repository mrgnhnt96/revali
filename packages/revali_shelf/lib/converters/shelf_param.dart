import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_param_annotations.dart';

class ShelfParam {
  const ShelfParam({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.importPath,
    required this.paramAnnotations,
  });

  factory ShelfParam.fromMeta(MetaParam param) {
    final importString = param.typeElement.librarySource?.uri.toString();

    ShelfImports? importPath;
    if (importString != null) {
      importPath = ShelfImports([importString]);
    }

    final paramAnnotations = ShelfParamAnnotations.fromMeta(param);

    return ShelfParam(
      name: param.name,
      type: param.type,
      isNullable: param.nullable,
      isRequired: param.isRequired,
      isNamed: param.isNamed,
      defaultValue: param.defaultValue,
      hasDefaultValue: param.hasDefaultValue,
      importPath: importPath,
      paramAnnotations: paramAnnotations,
    );
  }

  factory ShelfParam.fromElement(ParameterElement element) {
    final importString = element.librarySource?.uri.toString();

    ShelfImports? importPath;
    if (importString != null) {
      importPath = ShelfImports([importString]);
    }

    final paramAnnotations = ShelfParamAnnotations.fromElement(element);

    return ShelfParam(
      name: element.name,
      type: element.type.getDisplayString(withNullability: false),
      isNullable: element.type.nullabilitySuffix == NullabilitySuffix.question,
      isRequired: element.isRequiredNamed,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: importPath,
      paramAnnotations: paramAnnotations,
    );
  }

  final String name;
  final String type;
  final bool isNullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final bool hasDefaultValue;
  final ShelfImports? importPath;
  final ShelfParamAnnotations? paramAnnotations;

  Iterable<String> get imports sync* {
    if (importPath case final importPath?) {
      yield* importPath.imports;
    }

    if (paramAnnotations?.imports case final imports?) {
      yield* imports;
    }
  }
}
