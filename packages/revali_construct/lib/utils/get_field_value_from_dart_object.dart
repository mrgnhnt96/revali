import 'package:analyzer/dart/constant/value.dart';

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

DartObject? getFieldObjectFromDartObject(DartObject obj, String fieldName) {
  // Traverse the inheritance chain to find the field
  DartObject? currentObj = obj;
  while (currentObj != null) {
    final field = currentObj.getField(fieldName);
    if (field != null) {
      return field;
    }
    currentObj = currentObj.getField('(super)');
  }
  return null;
}
