import 'package:analyzer/dart/constant/value.dart';
import 'package:equatable/equatable.dart';
import 'package:zora_annotations/zora_annotations.dart';

class MethodAnnotation extends Equatable implements Method {
  const MethodAnnotation(this.name, {required this.path});

  static MethodAnnotation fromAnnotation(DartObject annotation) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final path = getFieldValueFromDartObject(annotation, 'path');

    return MethodAnnotation(name, path: path);
  }

  @override
  final String name;

  @override
  final String? path;

  @override
  List<Object?> get props => [name];
}

String? getFieldValueFromDartObject(DartObject obj, String fieldName) {
  // Traverse the inheritance chain to find the field
  DartObject? currentObj = obj;
  while (currentObj != null) {
    final field = currentObj.getField(fieldName);
    if (field != null) {
      return field.toStringValue();
    }
    currentObj = currentObj.getField('(super)');
  }
  return null;
}
