import 'package:code_builder/code_builder.dart';
import 'package:revali_server/makers/parts/get_params.dart';
import 'package:revali_server/revali_server.dart';

Expression createClass(ServerClass c) {
  final (:positioned, :named) = getParams(c.params);

  final constructor = refer(c.className).newInstance(positioned, named);

  return constructor;
}
