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
    );
  }

  final String name;
  final String type;
  final bool isNullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final bool hasDefaultValue;
}
