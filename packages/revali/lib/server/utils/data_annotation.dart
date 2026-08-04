import 'package:revali/server/converters/base_parameter_annotation.dart';
import 'package:revali_core/types/annotation_type.dart';

class DataAnnotation implements BaseParameterAnnotation {
  const DataAnnotation();

  @override
  String? get name => null;

  @override
  AnnotationType get type => AnnotationType.data;
}
