import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/simple_parameter_annotation.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

Expression createArgFromData(ServerParam param) {
  var dataVar = refer('context').property('data').property('get').call([]);

  if (createThrowMissingArgument(
    const SimpleParameterAnnotation(type: AnnotationType.data),
    param,
  )
      case final thrown?) {
    dataVar = dataVar.ifNullThen(thrown);
  }

  return createDefaultArgument(dataVar, param) ?? dataVar;
}
