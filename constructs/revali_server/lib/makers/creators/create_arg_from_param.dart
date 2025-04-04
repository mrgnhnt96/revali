import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

Expression createArgFromParam(
  ServerParamAnnotation annotation,
  ServerParam param,
) {
  final paramsRef =
      refer('context').property('request').property('pathParameters');

  var paramValue =
      paramsRef.index(literalString(annotation.name ?? param.name));

  if (createThrowMissingArgument(annotation, param) case final thrown?) {
    paramValue = paramValue.ifNullThen(thrown);
  }

  paramValue = createDefaultArgument(paramValue, param);

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: AnnotationType.param,
      access: paramValue,
    );
  } else if (param.type.hasFromJson) {
    return createFromJsonArg(
      param.type,
      access: paramValue,
    );
  }

  return paramValue;
}
