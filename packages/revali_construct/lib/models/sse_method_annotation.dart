import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_construct/models/method_annotation.dart';
import 'package:revali_construct/utils/get_field_value_from_dart_object.dart';

base class SseMethodAnnotation extends MethodAnnotation {
  const SseMethodAnnotation(super.name, {required super.path});

  factory SseMethodAnnotation.fromAnnotation(DartObject annotation) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final path = getFieldValueFromDartObject(annotation, 'path');

    return SseMethodAnnotation(name, path: path);
  }

  @override
  List<Object?> get props => [name, path];
}
