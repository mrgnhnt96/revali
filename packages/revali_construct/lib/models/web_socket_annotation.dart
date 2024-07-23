import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/method_annotation.dart';
import 'package:revali_construct/utils/get_field_value_from_dart_object.dart';

class WebSocketAnnotation extends MethodAnnotation {
  WebSocketAnnotation(
    super.name, {
    required this.mode,
    required super.path,
    required this.ping,
  });

  factory WebSocketAnnotation.fromAnnotation(
    DartObject annotation, {
    required String name,
    required String? path,
  }) {
    final name = getFieldValueFromDartObject(annotation, 'name');

    if (name == null) {
      throw Exception('Method name is required');
    }

    final modeRaw = getFieldObjectFromDartObject(annotation, 'mode');
    final modeName = modeRaw?.getField('_name')?.toStringValue();
    var mode = WebSocketMode.twoWay;
    if (modeName != null) {
      mode = WebSocketMode.values.byName(modeName);
    }
    Duration? ping;

    if (getFieldObjectFromDartObject(annotation, 'ping') case final pingRaw?) {
      if (pingRaw.getField('_duration')?.toIntValue() case final duration?) {
        ping = Duration(microseconds: duration);
      }
    }

    return WebSocketAnnotation(
      name,
      mode: mode,
      ping: ping,
      path: path,
    );
  }

  final Duration? ping;
  final WebSocketMode mode;

  @override
  List<Object?> get props => [name, path, mode, ping];
}
