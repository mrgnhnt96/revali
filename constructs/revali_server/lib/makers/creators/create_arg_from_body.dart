import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/creators/get_raw_type.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

Expression createArgFromBody(
  ServerBodyAnnotation annotation,
  ServerParam param,
) {
  var bodyVar = refer('context').property('request').property('body');

  if (annotation.access case final access?) {
    bodyVar = bodyVar.property('data?');
    for (final part in access) {
      bodyVar = bodyVar.index(literalString(part));
    }

    if (createThrowMissingArgument(
      annotation,
      param,
      location: access.join('.'),
    )
        case final thrown?) {
      bodyVar = bodyVar.ifNullThen(thrown);
    }
  } else {
    bodyVar = bodyVar.property('data');
  }

  bodyVar = createDefaultArgument(bodyVar, param);

  if (annotation.pipe case final pipe?) {
    final access = annotation.access;
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: access == null
          ? literalNull
          : literalList([
              for (final part in access) literalString(part),
            ]),
      nameOfParameter: param.name,
      type: AnnotationType.body,
      access: bodyVar,
    );
  }

  if (param.type.hasFromJson) {
    return createFromJsonArg(
      param.type,
      access: bodyVar,
    );
  }

  final fromJson = createFromJson(param.type, refer('data'));

  if (fromJson == null) {
    return bodyVar;
  }

  return createSwitchPattern(bodyVar, {
    declareFinal('data', type: getRawType(param.type)): fromJson,
    if (param.type.isNullable) literalNull: literalNull,
    const Code('_'): createMissingArgumentException(
      key: param.name,
      location: '@${AnnotationType.body.name}',
    ).thrown,
  });
}
