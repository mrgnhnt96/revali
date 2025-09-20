import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotation.dart';

Expression createParamVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerParamAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  final paramsRef = refer(
    'context',
  ).property('request').property('pathParameters');

  return paramsRef.index(literalString(annotation.name ?? param.name));
}
