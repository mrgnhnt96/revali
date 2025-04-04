import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';

Expression createArgFromData(ServerParam param) {
  final dataVar = refer('context').property('data').property('get').call([]);

  return createDefaultArgument(dataVar, param) ?? dataVar;
}
