import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_cookie_annotation.dart';
import 'package:revali_server/converters/server_param.dart';

Expression createCookieVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerCookieAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  final cookieVar = refer('context')
      .property('request')
      .property('headers')
      .property('cookies');

  return cookieVar.index(literalString(annotation.name ?? param.name));
}
