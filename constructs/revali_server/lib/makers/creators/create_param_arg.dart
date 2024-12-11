// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_binds.dart';
import 'package:revali_server/makers/creators/create_arg_from_body.dart';
import 'package:revali_server/makers/creators/create_arg_from_custom_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_data.dart';
import 'package:revali_server/makers/creators/create_arg_from_header.dart';
import 'package:revali_server/makers/creators/create_arg_from_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_query.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

final impliedArguments = <String, Expression>{
  // --- dependency injection ---
  (DI).name: refer('di'),
  // --- response ---
  (MutableHeaders).name:
      refer('context').property('response').property('headers'),
  (MutableBody).name: refer('context').property('response').property('body'),
  (MutableResponse).name: refer('context').property('response'),
  (RestrictedMutableResponse).name: refer('context').property('response'),
  // --- request ---
  (ReadOnlyHeaders).name:
      refer('context').property('request').property('headers'),
  (ReadOnlyRequest).name: refer('context').property('request'),
  (MutableRequest).name: refer('context').property('request'),
  (ReadOnlyBody).name: refer('context').property('request').property('body'),
  // --- meta ---
  (ReadOnlyMeta).name: refer('context').property('meta'),
  (WriteOnlyMeta).name: refer('context').property('meta'),
  (MetaHandler).name: refer('context').property('meta'),
  (ReadOnlyMetaDetailed).name: refer('context').property('meta'),
  // --- data ---
  (DataHandler).name: refer('context').property('data'),
  (ReadOnlyData).name: refer('context').property('data'),
  (WriteOnlyData).name: refer('context').property('data'),
};

Expression createParamArg(
  ServerParam param, {
  Expression? defaultExpression,
  Map<String, Expression> customParams = const {},
}) {
  if (impliedArguments[param.type] case final expression?) {
    return expression;
  }

  if (customParams[param.type] case final expression?) {
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
    return createGetFromDi();
  }

  if (annotation.data) {
    return createArgFromData(param);
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

  if (annotation.bind case final bind?) {
    return createArgFromBind(bind, param);
  }

  if (annotation.binds case final binds?) {
    return createArgFromBinds(binds, param);
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
