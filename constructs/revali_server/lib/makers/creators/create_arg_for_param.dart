import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_arg_from_binds.dart';
import 'package:revali_server/makers/creators/create_arg_from_data.dart';
import 'package:revali_server/makers/creators/create_body_var.dart';
import 'package:revali_server/makers/creators/create_cookie_var.dart';
import 'package:revali_server/makers/creators/create_from_json.dart';
import 'package:revali_server/makers/creators/create_header_var.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_param_var.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/creators/create_quer_var.dart';
import 'package:revali_server/makers/creators/get_raw_type.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';

Expression createArgForParam(
  BaseParameterAnnotation annotation,
  ServerParam param,
) {
  var variable = switch (annotation.type) {
    AnnotationType.body => createBodyVar(annotation),
    AnnotationType.query ||
    AnnotationType.queryAll =>
      createQueryVar(annotation, param),
    AnnotationType.cookie => createCookieVar(annotation, param),
    AnnotationType.param => createParamVar(annotation, param),
    AnnotationType.header ||
    AnnotationType.headerAll =>
      createHeaderVar(annotation, param),
    AnnotationType.binds => createBindsVar(annotation, param),
    AnnotationType.data => createDataVar(),
  };

  if (annotation.type
      case AnnotationType.headerAll || AnnotationType.queryAll) {
    variable = switch (param.type.iterableType) {
      IterableType.list => variable.nullSafeProperty('toList').call([]),
      IterableType.set => variable.nullSafeProperty('toSet').call([]),
      IterableType.iterable => variable,
      null => variable,
    };
  }

  if (annotation case HasPipe(:final pipe?)) {
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: literalNull,
      nameOfParameter: param.name,
      type: annotation.type,
      access: variable,
    );
  }

  final fromJson = createFromJson(param.type, refer('data'));

  return createSwitchPattern(variable, {
    Block.of([
      if (getRawType(param.type).replaceAll('?', '') case final type) ...[
        declareFinal('data', type: refer(type)).code,
        if (type case final String symbol when symbol.startsWith('Map')) ...[
          const Code('when'),
          refer('data').property('isNotEmpty').code,
        ],
      ],
    ]): fromJson ?? refer('data'),
    if (param.defaultValue case final defaultValue?)
      const Code('_'): CodeExpression(Code(defaultValue))
    else ...{
      if (param.type.isNullable) literalNull: literalNull,
      const Code('_'): createMissingArgumentException(
        key: param.name,
        location: '@${AnnotationType.body.name}',
      ).thrown,
    },
  });
}
