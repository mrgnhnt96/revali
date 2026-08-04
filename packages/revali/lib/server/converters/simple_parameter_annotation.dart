import 'package:revali/server/converters/base_parameter_annotation.dart';
import 'package:revali_core/revali_core.dart';

class SimpleParameterAnnotation implements BaseParameterAnnotation {
  const SimpleParameterAnnotation({required this.type, this.name});

  @override
  final String? name;

  @override
  final AnnotationType type;
}
