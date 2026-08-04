// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_app.dart';
import 'package:revali/server/makers/utils/get_params.dart';
import 'package:revali/server/makers/utils/type_extensions.dart';
import 'package:revali_core/revali_core.dart';

Expression createApp(ServerApp app) {
  final (:positioned, :named) = getParams(
    app.params,
    inferredParams: {(Args).name: refer('args')},
  );

  final expression = refer(app.className);

  if (app.constructor.isEmpty) {
    return expression.newInstance(positioned, named);
  } else {
    return expression.newInstanceNamed(app.constructor, positioned, named);
  }
}
