import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';

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
      (!param.type.isNullable && annotation.pipe == null)) {
    paramValue = paramValue.ifNullThen(
      createMissingArgumentException(
        key: annotation.name ?? param.name,
        location: '@${AnnotationType.param.name}',
      ).thrown.parenthesized,
    );
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: AnnotationType.param,
      access: paramValue,
    );
  } else if (param.type.hasFromJsonConstructor) {
    return createFromJsonArg(
      param.type,
      access: paramValue,
    );
  }

  return paramValue;
}
