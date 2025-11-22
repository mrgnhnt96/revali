import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_construct/types/annotation_getter.dart';
import 'package:revali_construct/utils/annotation_getter_impl.dart';

class MetaParam {
  const MetaParam({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.annotationsFor,
    required this.literalValue,
  });

  factory MetaParam.fromParam(FormalParameterElement param) {
    return MetaParam(
      name: param.name3 ?? (throw Exception('Parameter name is null')),
      type: MetaType.fromType(param.type),
      literalValue: null,
      isRequired: param.isRequired,
      isNamed: param.isNamed,
      defaultValue: param.defaultValueCode,
      annotationsFor:
          ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
              getAnnotations(
                element: param,
                onMatch: onMatch,
                onNonMatch: onNonMatch,
              ),
    );
  }

  final String name;
  final MetaType type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final AnnotationMapper annotationsFor;
  final String? literalValue;

  bool get hasDefaultValue => defaultValue != null;
}
