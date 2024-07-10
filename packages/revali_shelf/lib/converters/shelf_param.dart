import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_param_annotations.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfParam with ExtractImport {
  ShelfParam({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.importPath,
    required this.annotations,
    required this.typeImport,
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
      annotations: paramAnnotations,
      typeImport: param.typeImport,
    );
  }

  factory ShelfParam.fromElement(ParameterElement element) {
    final importString = element.librarySource?.uri.toString();

    ShelfImports? importPath;
    if (importString != null) {
      importPath = ShelfImports([importString]);
    }

    final paramAnnotations = ShelfParamAnnotations.fromElement(element);

    String? typeImport;

    if (element.library?.isInSdk == false) {
      typeImport = element.type.element?.librarySource?.uri.toString();
    }

    return ShelfParam(
      name: element.name,
      type: element.type.getDisplayString(withNullability: false),
      typeImport: typeImport,
      isNullable: element.type.nullabilitySuffix == NullabilitySuffix.question,
      isRequired: element.isRequiredNamed,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: importPath,
      annotations: paramAnnotations,
    );
  }

  final String name;
  final String type;
  final bool isNullable;
  final bool isRequired;
  final bool isNamed;
  final String? typeImport;
  final String? defaultValue;
  final bool hasDefaultValue;
  final ShelfImports? importPath;
  final ShelfParamAnnotations annotations;

  @override
  List<ExtractImport?> get extractors => [annotations];

  @override
  List<ShelfImports?> get imports => [importPath];
}
