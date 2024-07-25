// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_mimic.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createArgFromCustomParam(
  ServerMimic annotation,
  ServerParam param,
) {
  final context = refer((CustomParamContextImpl).name).newInstanceNamed(
    'from',
    [
      refer('context'),
    ],
    {
      'nameOfParameter': literalString(param.name),
      'parameterType': refer(param.type),
    },
  );

  return createMimic(annotation).property('parse').call([context]).awaited;
}
