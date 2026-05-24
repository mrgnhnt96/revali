import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/makers/utils/wildcard_param.dart';

Expression createParamVar(
  BaseParameterAnnotation annotation,
  ServerParam param, {
  String routePath = '',
}) {
  if (annotation is! ServerParamAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  final paramKey = annotation.name ?? param.name;
  final wildcardKey = wildcardParamKey(routePath, paramKey);

  if (wildcardKey != null &&
      param.type.iterableType == IterableType.list &&
      param.type.name == 'List<String>') {
    return refer('context')
        .property('request')
        .property('wildcardParameters')
        .index(literalString(wildcardKey))
        .nullSafeProperty('toList')
        .call([]);
  }

  final paramsRef = refer(
    'context',
  ).property('request').property('pathParameters');

  return paramsRef.index(literalString(wildcardKey ?? paramKey));
}
