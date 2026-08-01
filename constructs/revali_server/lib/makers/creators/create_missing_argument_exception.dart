// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createMissingArgumentException({
  required String key,
  required String location,
  String? expectedType,
  Expression? actualType,
  String? message,
}) {
  return refer((MissingArgumentException).name).newInstance([], {
    'key': literalString(key),
    'location': literalString(location),
    if (expectedType != null) 'expectedType': literalString(expectedType),
    if (actualType != null) 'actualType': actualType,
    if (message != null) 'message': literalString(message),
  });
}

/// Runtime expression: `value?.runtimeType.toString() ?? 'null'`.
Expression actualTypeOf(Expression value) {
  return value
      .nullSafeProperty('runtimeType')
      .property('toString')
      .call([])
      .ifNullThen(literalString('null'));
}
