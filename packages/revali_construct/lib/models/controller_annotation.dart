import 'package:analyzer/dart/constant/value.dart';

class ControllerAnnotation {
  const ControllerAnnotation(this.path);

  factory ControllerAnnotation.fromAnnotation(DartObject annotation) {
    final path = annotation.getField('path')?.toStringValue();

    if (path == null) {
      throw Exception('Controller path is required');
    }

    return ControllerAnnotation(path);
  }

  final String path;
}
