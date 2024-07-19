import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';

Expression createArgFromParam(
  ServerParamAnnotation annotation,
  ServerParam param,
) {
  final paramsRef =
      refer('context').property('request').property('pathParameters');

  var paramValue =
      paramsRef.index(literalString(annotation.name ?? param.name));

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!param.isNullable && annotation.pipe == null)) {
    paramValue = paramValue
        // TODO(MRGNHNT): Throw custom exception here
        .ifNullThen(literalString('Missing value!').thrown.parenthesized);
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
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
