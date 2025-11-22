import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/method_annotation.dart';
import 'package:revali_construct/utils/get_field_value_from_dart_object.dart';

final class WebSocketAnnotation extends MethodAnnotation {
  const WebSocketAnnotation(
    super.name, {
    required this.mode,
    required super.path,
    required this.ping,
    required this.triggerOnConnect,
  });

  factory WebSocketAnnotation.fromAnnotation(
    DartObject annotation, {
    required String name,
    required String? path,
  }) {
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

    final triggerOnConnect =
        getFieldObjectFromDartObject(
          annotation,
          'triggerOnConnect',
        )?.toBoolValue() ??
        false;

    return WebSocketAnnotation(
      name,
      mode: mode,
      ping: ping,
      path: path,
      triggerOnConnect: triggerOnConnect,
    );
  }

  final Duration? ping;
  final WebSocketMode mode;
  final bool triggerOnConnect;

  @override
  List<Object?> get props => [name, path, mode, ping, triggerOnConnect];
}
