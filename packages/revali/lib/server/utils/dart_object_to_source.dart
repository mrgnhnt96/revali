// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';

/// Converts a [DartObject] (compile-time constant) to its Dart source code
/// representation.
String dartObjectToSource(DartObject object) {
  if (object.isNull) {
    return 'null';
  }

  if (object.toBoolValue() case final bool value) {
    return value ? 'true' : 'false';
  }

  if (object.toIntValue() case final int value) {
    return value.toString();
  }

  if (object.toDoubleValue() case final double value) {
    return value.toString();
  }

  if (object.toStringValue() case final String value) {
    return "'${value.replaceAll("'", r"\'")}'";
  }

  if (object.toTypeValue() case final DartType type) {
    return type.getDisplayString();
  }

  if (object.toSymbolValue() case final String value) {
    return '#$value';
  }

  throw ArgumentError('Cannot convert DartObject to source: $object');
}
