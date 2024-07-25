import 'package:analyzer/dart/constant/value.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/web_socket_annotation.dart';
import 'package:revali_construct/utils/get_field_value_from_dart_object.dart';

class MethodAnnotation extends Equatable implements Method {
  const MethodAnnotation(
    this.name, {
    required this.path,
  });

  factory MethodAnnotation.fromAnnotation(DartObject annotation) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final path = getFieldValueFromDartObject(annotation, 'path');

    final isWebSocket =
        annotation.type?.getDisplayString(withNullability: false) ==
            '$WebSocket';

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

  @override
  final String name;

  @override
  final String? path;

  bool get isWebSocket => this is WebSocketAnnotation;
  WebSocketAnnotation get asWebSocket => this as WebSocketAnnotation;

  @override
  List<Object?> get props => [name, path];
}
