import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_construct/types/annotation_getter.dart';

class MetaParam {
  const MetaParam({
    required this.name,
    required this.type,
    required this.nullable,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.annotationsFor,
  });

  final String name;
  final MetaType type;
  final bool nullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final AnnotationMapper annotationsFor;

  @Deprecated('Use type.importPath')
  String? get typeImport => type.importPath;

  bool get hasDefaultValue => defaultValue != null;
}
