import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_arg_from_binds.dart';
import 'package:revali_server/makers/creators/create_body_var.dart';
import 'package:revali_server/makers/creators/create_cookie_var.dart';
import 'package:revali_server/makers/creators/create_data_var.dart';
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
    AnnotationType.data => createDataVar(param),
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
      param: param,
      annotation: annotation,
      access: variable,
    );
  }

  final fromJson = switch (param.annotations.data) {
    true => refer('data'),
    false => createFromJson(param.type, refer('data')),
  };

  if (param.type.isDynamic) {
    return fromJson ?? variable;
  }

  final rawType = switch (param.annotations.data) {
    true => param.type.name,
    false => getRawType(param.type).replaceAll('?', ''),
  };

  return createSwitchPattern(variable, {
    Block.of([
      declareFinal('data', type: refer(rawType)).code,
      if (rawType.startsWith('Map')) ...[
        const Code('when'),
        refer('data').property('isNotEmpty').code,
      ],
    ]): fromJson ??
        switch (param.type) {
          ServerType(:final iterableType?) => switch (iterableType) {
              IterableType.list => refer('data').property('cast').call([]),
              IterableType.set => refer('data')
                  .property('toSet')
                  .call([])
                  .property('cast')
                  .call([]),
              IterableType.iterable => refer('data'),
            },
          _ => refer('data'),
        },
    if (param.defaultValue case final defaultValue?)
      const Code('_'): CodeExpression(Code(defaultValue))
    else ...{
      if (param.type.isNullable)
        Block.of([
          literalNull.code,
          if (rawType.startsWith('Map')) ...[
            const Code('||'),
            const Code('Map()'),
          ] else if (rawType.startsWith('List')) ...[
            const Code('||'),
            const Code('List()'),
          ],
        ]): literalNull,
      const Code('_'): createMissingArgumentException(
        key: annotation.name ?? param.name,
        location: annotation.type.location,
      ).thrown,
    },
  });
}
