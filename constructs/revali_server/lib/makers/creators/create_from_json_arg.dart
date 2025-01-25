import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_type.dart';

Expression createFromJsonArg(ServerType type, {required Expression access}) {
  return refer(type.name).property('fromJson').call([access]);
}
