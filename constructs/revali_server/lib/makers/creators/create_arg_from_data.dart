import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/pipe/annotation_type.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';

Expression createArgFromData(ServerParam param) {
  var dataVar = refer('context').property('data').property('get').call([]);

  if (!param.isNullable) {
    dataVar = dataVar.ifNullThen(
      createMissingArgumentException(
        key: param.name,
        location: '@${AnnotationType.data.name}',
      ).thrown.parenthesized,
    );
  }

  return dataVar;
}
