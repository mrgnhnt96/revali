// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_arg_for_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_custom_param.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/data_annotation.dart';

final impliedArguments = <String, Expression>{
  // --- dependency injection ---
  (DI).name: refer('di'),
  // --- response ---
  (Headers).name: refer('context').property('response').property('headers'),
  (Cookies).name: refer(
    'context',
  ).property('response').property('headers').property('cookies'),
  (SetCookies).name: refer(
    'context',
  ).property('response').property('headers').property('setCookies'),
  (SetCookies).name: refer(
    'context',
  ).property('response').property('headers').property('setCookies'),
  (Body).name: refer('context').property('response').property('body'),
  (Response).name: refer('context').property('response'),
  // --- request ---
  (Headers).name: refer('context').property('response').property('headers'),
  (RequestHeaders).name: refer(
    'context',
  ).property('request').property('headers'),
  (ResponseHeaders).name: refer(
    'context',
  ).property('response').property('headers'),
  (Request).name: refer('context').property('request'),
  (Body).name: refer('context').property('request').property('body'),
  (Cookies).name: refer(
    'context',
  ).property('request').property('headers').property('cookies'),
  // --- meta ---
  (Meta).name: refer('context').property('meta'),
  (MetaScope).name: refer('context').property('meta'),
  (RouteEntry).name: refer('context').property('route'),
  (Context).name: refer('context'),
  // --- data ---
  (Data).name: refer('context').property('data'),
  (CleanUp).name: refer('context')
      .property('data')
      .property('get')
      .call([])
      .ifNullThen(
        createMissingArgumentException(
          key: 'cleanUp',
          location: '@data',
        ).thrown.parenthesized,
      ),
  // --- reflect ---
  (ReflectHandler).name: refer('context').property('reflect'),
};

Expression createParamArg(
  ServerParam param, {
  Expression? defaultExpression,
  Map<String, Expression> customParams = const {},

  /// When true, the field of the class will be referenced instead of creating a
  /// new argument. This only applies if [ServerParam.argument] exists
  /// or [ServerParam.hasDefaultValue]
  bool useField = false,
}) {
  if (impliedArguments[param.type.name] case final expression?) {
    return expression;
  }

  if (impliedArguments[param.type.name.split('<').first]
      case final expression?) {
    return expression;
  }

  if (customParams[param.type.name] case final expression?) {
    return expression;
  }

  if (customParams[param.type.name.split('<').first] case final expression?) {
    return expression;
  }

  final annotation = param.annotations;
  if (!annotation.hasAnnotation &&
      !param.hasDefaultValue &&
      !param.hasArgument) {
    if (!param.type.isPrimitive) {
      if (defaultExpression != null) {
        if (useField) {
          return refer(param.name);
        }

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
    if (useField) {
      return refer(param.name);
    }

    return CodeExpression(Code(value));
  }

  if (annotation.dep) {
    if (useField) {
      return refer(param.name);
    }

    return createGetFromDi();
  }

  if (annotation.bind case final bind?) {
    return createArgFromBind(bind, param);
  }

  if (annotation.baseAnnotation case final annotation?) {
    return createArgForParam(annotation, param);
  }

  if (annotation.data) {
    return createArgForParam(const DataAnnotation(), param);
  }

  if (defaultExpression != null) {
    return defaultExpression;
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
