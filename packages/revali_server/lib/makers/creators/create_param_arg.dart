import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_mimic.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createParamArg(
  ServerParam param,
) {
  final annotation = param.annotations;

  if (param.type == '$DI') {
    return refer('di');
  }

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
    var bodyVar = refer('context').property('request').property('body');

    if (bodyAnnotation.access case final access?) {
      bodyVar = bodyVar.property('data?');
      for (final part in access) {
        bodyVar = bodyVar.index(literalString(part));

        final acceptsNull = bodyAnnotation.acceptsNull;
        if ((acceptsNull != null && !acceptsNull) ||
            (!param.isNullable && bodyAnnotation.pipe == null)) {
          bodyVar = bodyVar
              // TODO(MRGNHNT): Throw custom exception here
              .ifNullThen(literalString('Missing value!').thrown.parenthesized);
        }
      }
    } else {
      bodyVar = bodyVar.property('data');
    }

    if (bodyAnnotation.pipe case final pipe?) {
      final access = bodyAnnotation.access;
      return createPipeContext(
        pipe,
        annotationArgument: access == null
            ? literalNull
            : literalList([
                for (final part in access) literalString(part),
              ]),
        nameOfParameter: param.name,
        type: AnnotationType.body,
        access: bodyVar,
      );
    }

    return bodyVar;
  }

  if (annotation.param case final paramAnnotation?) {
    final paramsRef =
        refer('context').property('request').property('pathParameters');

    var paramValue =
        paramsRef.index(literalString(paramAnnotation.name ?? param.name));

    final acceptsNull = paramAnnotation.acceptsNull;
    if ((acceptsNull != null && !acceptsNull) ||
        (!param.isNullable && paramAnnotation.pipe == null)) {
      paramValue = paramValue
          // TODO(MRGNHNT): Throw custom exception here
          .ifNullThen(literalString('Missing value!').thrown.parenthesized);
    }

    if (paramAnnotation.pipe case final pipe?) {
      final name = paramAnnotation.name;
      return createPipeContext(
        pipe,
        annotationArgument: name == null ? literalNull : literalString(name),
        nameOfParameter: param.name,
        type: AnnotationType.param,
        access: paramValue,
      );
    }

    return paramValue;
  }

  if (annotation.query case final queryAnnotation?) {
    Expression queryVar = refer('context').property('request');

    if (queryAnnotation.all) {
      queryVar = queryVar.property('queryParametersAll');
    } else {
      queryVar = queryVar.property('queryParameters');
    }

    var queryValue =
        queryVar.index(literalString(queryAnnotation.name ?? param.name));

    final acceptsNull = queryAnnotation.acceptsNull;
    if ((acceptsNull != null && !acceptsNull) ||
        (!param.isNullable && queryAnnotation.pipe == null)) {
      queryValue = queryValue
          // TODO(MRGNHNT): Throw custom exception here
          .ifNullThen(literalString('Missing value!').thrown.parenthesized);
    }

    if (queryAnnotation.pipe case final pipe?) {
      final name = queryAnnotation.name;
      return createPipeContext(
        pipe,
        annotationArgument: name == null ? literalNull : literalString(name),
        nameOfParameter: param.name,
        type: queryAnnotation.all
            ? AnnotationType.queryAll
            : AnnotationType.query,
        access: queryValue,
      );
    }

    return queryValue;
  }

  if (annotation.customParam case final customParam?) {
    final context = refer((CustomParamContextImpl).name).newInstanceNamed(
      'from',
      [
        refer('context'),
      ],
      {
        'nameOfParameter': literalString(param.name),
        'parameterType': refer(param.type),
      },
    );

    return createMimic(customParam).property('parse').call([context]).awaited;
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
