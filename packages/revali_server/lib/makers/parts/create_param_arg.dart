import 'package:code_builder/code_builder.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/makers/parts/create_class.dart';
import 'package:revali_server/makers/parts/mimic.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/revali_server.dart';

Expression createParamArg(
  ServerParam param,
) {
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

  if (annotation.body case final body?) {
    var bodyVar = refer('context').property('request').property('body');

    if (body.access case final access?) {
      bodyVar = bodyVar.property('data?');
      for (final part in access) {
        bodyVar = bodyVar.index(literalString(part));

        final acceptsNull = body.acceptsNull;
        if ((acceptsNull != null && !acceptsNull) ||
            (!param.isNullable && body.pipe == null)) {
          bodyVar = bodyVar
              // TODO(MRGNHNT): Throw custom exception here
              .ifNullThen(literalString('Missing value!').thrown.parenthesized);
        }
      }
    } else {
      bodyVar = bodyVar.property('data');
    }

    if (body.pipe case final pipe?) {
      final pipeClass = createClass(pipe.pipe);

      return pipeClass.property('transform').call([bodyVar]);
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
      final pipeClass = createClass(pipe.pipe);

      final context = refer((PipeContextImpl).name).newInstanceNamed(
        'from',
        [
          refer('context'),
        ],
        {
          'arg': paramAnnotation.name == null
              ? literalNull
              : literalString(paramAnnotation.name!),
          'paramName': literalString(paramAnnotation.name ?? param.name),
          'type': refer('${ParamType.param}'),
        },
      );

      return pipeClass.property('transform').call([paramValue, context]);
    }

    return paramValue;
  }

  if (annotation.query case final query?) {
    Expression queryVar;

    if (query.all) {
      queryVar =
          refer('context').property('request').property('queryParametersAll');
    } else {
      queryVar =
          refer('context').property('request').property('queryParameters');
    }

    var queryValue = queryVar.index(literalString(query.name ?? param.name));

    final acceptsNull = query.acceptsNull;
    if ((acceptsNull != null && !acceptsNull) ||
        (!param.isNullable && query.pipe == null)) {
      queryValue = queryValue
          // TODO(MRGNHNT): Throw custom exception here
          .ifNullThen(literalString('Missing value!').thrown.parenthesized);
      ;
    }

    if (query.pipe case final pipe?) {
      final pipeClass = createClass(pipe.pipe);

      final context = refer((PipeContextImpl).name).newInstanceNamed(
        'from',
        [
          refer('context'),
        ],
        {
          'arg': query.name == null ? literalNull : literalString(query.name!),
          'paramName': literalString(query.name ?? param.name),
          'type':
              refer(query.all ? '${ParamType.queryAll}' : '${ParamType.query}'),
        },
      );

      return pipeClass.property('transform').call([queryValue, context]);
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
        'name': literalString(param.name),
        'type': refer(param.type),
      },
    );

    return mimic(customParam).property('parse').call([context]);
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
