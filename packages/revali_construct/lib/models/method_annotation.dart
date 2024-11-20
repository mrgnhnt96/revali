import 'package:analyzer/dart/constant/value.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/sse_method_annotation.dart';
import 'package:revali_construct/models/web_socket_annotation.dart';
import 'package:revali_construct/utils/get_field_value_from_dart_object.dart';

base class MethodAnnotation extends Method with EquatableMixin {
  const MethodAnnotation(
    super.name, {
    required super.path,
  });

  factory MethodAnnotation.fromAnnotation(DartObject annotation) {
    final className = annotation.type?.getDisplayString();

    if (className == '$SSE') {
      return SseMethodAnnotation.fromAnnotation(annotation);
    }

    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final path = getFieldValueFromDartObject(annotation, 'path');

    final isWebSocket = className == '$WebSocket';

    if (isWebSocket) {
      return WebSocketAnnotation.fromAnnotation(
        annotation,
        name: name,
        path: path,
      );
    }

    return MethodAnnotation(
      name,
      path: path,
    );
  }

  bool get isWebSocket => this is WebSocketAnnotation;
  WebSocketAnnotation get asWebSocket => this as WebSocketAnnotation;

  bool get isSse => this is SseMethodAnnotation;

  @override
  List<Object?> get props => [name, path];
}
