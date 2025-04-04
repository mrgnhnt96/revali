import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_query_annotation.dart';

Expression createQueryVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerQueryAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  var queryVar = refer('context').property('request');

  if (annotation.all) {
    queryVar = queryVar.property('queryParametersAll');
  } else {
    queryVar = queryVar.property('queryParameters');
  }

  return queryVar.index(literalString(annotation.name ?? param.name));
}
