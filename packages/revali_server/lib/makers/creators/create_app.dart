import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_app.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Expression createApp(ServerApp app) {
  final (:positioned, :named) = getParams(app.params);

  var expression = refer(app.className);

  if (app.constructor.isEmpty) {
    return expression.newInstance(positioned, named);
  } else {
    return expression.newInstanceNamed(app.constructor, positioned, named);
  }
}
