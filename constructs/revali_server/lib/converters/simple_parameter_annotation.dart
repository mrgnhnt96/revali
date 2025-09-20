import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';

class SimpleParameterAnnotation implements BaseParameterAnnotation {
  const SimpleParameterAnnotation({required this.type, this.name});

  @override
  final String? name;

  @override
  final AnnotationType type;
}
