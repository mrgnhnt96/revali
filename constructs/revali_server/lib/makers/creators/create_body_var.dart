import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_body_annotation.dart';

Expression createBodyVar(BaseParameterAnnotation annotation) {
  if (annotation is! ServerBodyAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  var bodyVar = refer('context').property('request').property('body');

  if (annotation.access case final access?) {
    bodyVar = bodyVar.property('data?');
    for (final part in access) {
      bodyVar = bodyVar.index(literalString(part));
    }
  } else {
    bodyVar = bodyVar.property('data');
  }

  return bodyVar;
}
