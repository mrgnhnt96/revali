import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

Expression createClass(
  ServerClass c, {
  Expression? defaultArg,
}) {
  final (:positioned, :named) = getParams(
    c.params,
    defaultExpression: defaultArg,
  );

  final constructor = refer(c.className).newInstance(positioned, named);

  return constructor;
}
