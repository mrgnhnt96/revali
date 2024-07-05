import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';

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
    return ShelfParam(
        name: param.name,
        type: param.type,
        isNullable: param.nullable,
        isRequired: param.isRequired,
        isNamed: param.isNamed,
        defaultValue: param.defaultValue,
        hasDefaultValue: param.hasDefaultValue,
        importPath: param.typeElement.library?.identifier);
  }

  factory ShelfParam.fromElement(ParameterElement element) {
    return ShelfParam(
      name: element.name,
      type: element.type.getDisplayString(withNullability: false),
      isNullable: element.type.nullabilitySuffix == NullabilitySuffix.question,
      isRequired: element.isRequiredNamed,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: element.library?.identifier,
    );
  }

  final String name;
  final String type;
  final bool isNullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final bool hasDefaultValue;
  final String? importPath;

  bool get isFileImport => importPath?.startsWith('file:') ?? false;
}
