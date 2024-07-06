import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';

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
  });

  factory ShelfParam.fromMeta(MetaParam param) {
    final importString = param.typeElement.librarySource?.uri.toString();

    param.annotationsFor(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            print(object);
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            print(object);
          },
        ),
        OnMatch(
          classType: Param,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            print(object);
          },
        ),
        OnMatch(
          classType: CustomParam,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            print(object);
          },
        ),
      ],
    );

    ShelfImports? importPath;
    if (importString != null) {
      importPath = ShelfImports([importString]);
    }
    return ShelfParam(
      name: param.name,
      type: param.type,
      isNullable: param.nullable,
      isRequired: param.isRequired,
      isNamed: param.isNamed,
      defaultValue: param.defaultValue,
      hasDefaultValue: param.hasDefaultValue,
      importPath: importPath,
    );
  }

  factory ShelfParam.fromElement(ParameterElement element) {
    final importString = element.librarySource?.uri.toString();

    ShelfImports? importPath;
    if (importString != null) {
      importPath = ShelfImports([importString]);
    }
    return ShelfParam(
      name: element.name,
      type: element.type.getDisplayString(withNullability: false),
      isNullable: element.type.nullabilitySuffix == NullabilitySuffix.question,
      isRequired: element.isRequiredNamed,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: importPath,
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
}
