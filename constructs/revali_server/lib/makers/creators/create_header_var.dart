import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_param.dart';

Expression createHeaderVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerHeaderAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  var headersRef = refer('context').property('request').property('headers');

  if (annotation.all) {
    headersRef = headersRef.property('getAll');
  } else {
    headersRef = headersRef.property('get');
  }

  return headersRef.call([literalString(annotation.name ?? param.name)]);
}
