import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_bind_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/creators/create_custom_param_context.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';

Expression createArgFromBind(
  ServerBindAnnotation annotation,
  ServerParam param,
) {
  var paramsRef = createClass(
    annotation.customParam.customParam,
    defaultArg: createGetFromDi(),
  ).property('parse').call([createCustomParamContext(param)]).awaited;

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) || !param.isNullable) {
    paramsRef = paramsRef.ifNullThen(
      createMissingArgumentException(
        key: param.name,
        location: '@${AnnotationType.bind.name}',
      ).thrown.parenthesized,
    );
  }

  return paramsRef;
}
