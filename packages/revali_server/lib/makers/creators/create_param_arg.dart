// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_body.dart';
import 'package:revali_server/makers/creators/create_arg_from_custom_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_header.dart';
import 'package:revali_server/makers/creators/create_arg_from_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_query.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

final impliedArguments = <String, Expression>{
  (DI).name: refer('di'),
  (MutableHeaders).name:
      refer('context').property('response').property('headers'),
  (ReadOnlyHeaders).name:
      refer('context').property('request').property('headers'),
  (ReadOnlyRequest).name: refer('context').property('request'),
};

Expression createParamArg(
  ServerParam param, {
  Expression? defaultExpression,
}) {
  if (impliedArguments[param.type] case final expression?) {
    return expression;
  }

  if (defaultExpression != null) {
    return defaultExpression;
  }

  final annotation = param.annotations;
  if (!annotation.hasAnnotation && !param.hasDefaultValue) {
    throw ArgumentError(
      'No annotation or default value for param ${param.name}',
    );
  }

  if (param.defaultValue case final value? when !annotation.hasAnnotation) {
    return CodeExpression(Code(value));
  }

  if (annotation.dep) {
    return refer('di').property('get').call([]);
  }

  if (annotation.body case final bodyAnnotation?) {
    return createArgFromBody(bodyAnnotation, param);
  }

  if (annotation.param case final paramAnnotation?) {
    return createArgFromParam(paramAnnotation, param);
  }

  if (annotation.query case final queryAnnotation?) {
    return createArgFromQuery(queryAnnotation, param);
  }

  if (annotation.header case final headerAnnotation?) {
    return createArgFromHeader(headerAnnotation, param);
  }

  if (annotation.customParam case final customParam?) {
    return createArgFromCustomParam(customParam, param);
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
