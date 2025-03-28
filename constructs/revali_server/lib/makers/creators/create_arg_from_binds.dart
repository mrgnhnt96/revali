import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_binds_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_bind_context.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';

Expression createArgFromBinds(
  ServerBindsAnnotation annotation,
  ServerParam param,
) {
  var paramsRef = createClass(annotation.bind.bind)
      .property('bind')
      .call([createBindContext(param)]).awaited;

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) || !param.type.isNullable) {
    paramsRef = paramsRef.ifNullThen(
      createMissingArgumentException(
        key: param.name,
        location: '@${AnnotationType.binds.name}',
      ).thrown.parenthesized,
    );
  }

  return paramsRef;
}
