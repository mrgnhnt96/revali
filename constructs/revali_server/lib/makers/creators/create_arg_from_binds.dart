import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_binds_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_bind_context.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

Expression createBindsVar(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  if (annotation is! ServerBindsAnnotation) {
    throw ArgumentError('Invalid annotation type: ${annotation.runtimeType}');
  }

  return createClass(annotation.bind.bind)
      .property('bind')
      .call([createBindContext(param)]).awaited;
}

Expression createArgFromBinds(
  ServerBindsAnnotation annotation,
  ServerParam param,
) {
  var paramsRef = createClass(annotation.bind.bind)
      .property('bind')
      .call([createBindContext(param)]).awaited;

  if (createThrowMissingArgument(annotation, param) case final thrown?) {
    paramsRef = paramsRef.ifNullThen(thrown);
  }

  if (param.defaultValue case final defaultValue?) {
    paramsRef = paramsRef.ifNullThen(CodeExpression(Code(defaultValue)));
  }

  return paramsRef;
}
