import 'package:analyzer/dart/constant/value.dart';
import 'package:equatable/equatable.dart';
import 'package:zora_core/zora_core.dart';

class MethodAnnotation extends Equatable implements Method {
  const MethodAnnotation(this.name);

  static fromAnnotation(DartObject annotation) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    return MethodAnnotation(name);
  }

  final String name;

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
