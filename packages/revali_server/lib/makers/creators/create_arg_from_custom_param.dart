// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_custom_param_context.dart';
import 'package:revali_server/makers/creators/create_mimic.dart';

Expression createArgFromCustomParam(
  ServerMimic annotation,
  ServerParam param,
) {
  return createMimic(annotation)
      .property('bind')
      .call([createCustomParamContext(param)]).awaited;
}
