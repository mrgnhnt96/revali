import 'package:revali_router_core/pipe/annotation_type.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';

class DataAnnotation implements BaseParameterAnnotation {
  const DataAnnotation();

  @override
  String? get name => null;

  @override
  AnnotationType get type => AnnotationType.data;
}
