import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_annotations/revali_annotations.dart';

class ControllerAnnotation {
  const ControllerAnnotation(this.path, {required this.type});

  factory ControllerAnnotation.fromAnnotation(DartObject annotation) {
    final path = annotation.getField('path')?.toStringValue();

    if (path == null) {
      throw Exception('Controller path is required');
    }

    final type = annotation.getField('type')?.variable?.displayName;

    if (type == null) {
      throw Exception('Controller type is required');
    }

    return ControllerAnnotation(path, type: InstanceType.values.byName(type));
  }

  final String path;
  final InstanceType type;
}
