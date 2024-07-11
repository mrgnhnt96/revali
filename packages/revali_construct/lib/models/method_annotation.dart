import 'package:analyzer/dart/constant/value.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_annotations/revali_annotations.dart';

class MethodAnnotation extends Equatable implements Method {
  const MethodAnnotation(
    this.name, {
    required this.path,
    required this.isWebSocket,
  });

  static MethodAnnotation fromAnnotation(DartObject annotation) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final path = getFieldValueFromDartObject(annotation, 'path');

    final isWebSocket =
        annotation.type?.getDisplayString(withNullability: false) ==
            '$WebSocket';

    return MethodAnnotation(
      name,
      path: path,
      isWebSocket: isWebSocket,
    );
  }

  @override
  final String name;

  @override
  final String? path;

  final bool isWebSocket;

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
