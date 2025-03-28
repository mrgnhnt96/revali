// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_binds.dart';
import 'package:revali_server/makers/creators/create_arg_from_body.dart';
import 'package:revali_server/makers/creators/create_arg_from_cookie.dart';
import 'package:revali_server/makers/creators/create_arg_from_custom_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_data.dart';
import 'package:revali_server/makers/creators/create_arg_from_header.dart';
import 'package:revali_server/makers/creators/create_arg_from_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_query.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

final impliedArguments = <String, Expression>{
  // --- dependency injection ---
  (DI).name: refer('di'),
  // --- response ---
  (MutableHeaders).name:
      refer('context').property('response').property('headers'),
  (MutableCookies).name: refer('context')
      .property('response')
      .property('headers')
      .property('cookies'),
  (MutableSetCookies).name: refer('context')
      .property('response')
      .property('headers')
      .property('setCookies'),
  (ReadOnlySetCookies).name: refer('context')
      .property('response')
      .property('headers')
      .property('setCookies'),
  (MutableBody).name: refer('context').property('response').property('body'),
  (MutableResponse).name: refer('context').property('response'),
  (RestrictedMutableResponse).name: refer('context').property('response'),
  // --- request ---
  (ReadOnlyHeaders).name:
      refer('context').property('request').property('headers'),
  (ReadOnlyRequest).name: refer('context').property('request'),
  (MutableRequest).name: refer('context').property('request'),
  (ReadOnlyBody).name: refer('context').property('request').property('body'),
  (ReadOnlyCookies).name: refer('context')
      .property('request')
      .property('headers')
      .property('cookies'),
  // --- meta ---
  (ReadOnlyMeta).name: refer('context').property('meta'),
  (WriteOnlyMeta).name: refer('context').property('meta'),
  (MetaHandler).name: refer('context').property('meta'),
  (ReadOnlyMetaDetailed).name: refer('context').property('meta'),
  // --- data ---
  (DataHandler).name: refer('context').property('data'),
  (ReadOnlyData).name: refer('context').property('data'),
  (WriteOnlyData).name: refer('context').property('data'),
  (CleanUp).name:
      refer('context').property('data').property('get').call([]).ifNullThen(
    createMissingArgumentException(key: 'cleanUp', location: '@data')
        .thrown
        .parenthesized,
  ),
};

Expression createParamArg(
  ServerParam param, {
  Expression? defaultExpression,
  Map<String, Expression> customParams = const {},

  /// When true, the field of the class will be referenced instead of creating a
  /// new argument. This only applies if [ServerParam.argument] exists
  bool useField = false,
}) {
  if (impliedArguments[param.type.name] case final expression?) {
    return expression;
  }

  if (customParams[param.type.name] case final expression?) {
    return expression;
  }

  final annotation = param.annotations;
  if (!annotation.hasAnnotation &&
      !param.hasDefaultValue &&
      !param.hasArgument) {
    if (!param.type.isPrimitive) {
      if (defaultExpression != null) {
        return defaultExpression;
      }
    }

    if (param.type.isNullable) {
      return literalNull;
    }

    throw ArgumentError(
      'No annotation or default value for param "${param.name}"',
    );
  }

  if (param.argument case final value?) {
    if (useField) {
      return refer(value.parameterName);
    }

    if (value.isInjectable) {
      return createGetFromDi();
    }

    return CodeExpression(Code(value.source));
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
  if (annotation.cookie case final cookieAnnotation?) {
    return createArgFromCookie(cookieAnnotation, param);
  }

  if (annotation.bind case final bind?) {
    return createArgFromBind(bind, param);
  }

  if (annotation.binds case final binds?) {
    return createArgFromBinds(binds, param);
  }

  if (defaultExpression != null) {
    return defaultExpression;
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
