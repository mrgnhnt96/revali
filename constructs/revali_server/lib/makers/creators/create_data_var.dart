import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';

Expression createDataVar(ServerParam param) {
  return refer('context')
      .property('data')
      .property('get')
      .call([], {}, [refer(param.type.name)]);
}
