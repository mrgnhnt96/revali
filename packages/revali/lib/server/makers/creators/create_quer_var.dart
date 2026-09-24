import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/base_parameter_annotation.dart';
import 'package:revali/server/converters/server_param.dart';
import 'package:revali/server/converters/server_query_annotation.dart';

Expression createQueryVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerQueryAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  var queryVar = refer('context').property('request');

  // Query values are coerced (`?id=42` arrives as `42`). A pipe that declares
  // a `String` input must receive the value exactly as it was sent.
  if (annotation.pipe?.convertFrom.nonNullName == 'String') {
    queryVar = queryVar.property('uri');
  }

  if (annotation.all) {
    queryVar = queryVar.property('queryParametersAll');
  } else {
    queryVar = queryVar.property('queryParameters');
  }

  return queryVar.index(literalString(annotation.name ?? param.name));
}
