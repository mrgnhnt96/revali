import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/base_parameter_annotation.dart';
import 'package:revali/server/converters/has_pipe.dart';
import 'package:revali/server/converters/server_param.dart';
import 'package:revali/server/makers/creators/create_arg_from_binds.dart';
import 'package:revali/server/makers/creators/create_body_var.dart';
import 'package:revali/server/makers/creators/create_cookie_var.dart';
import 'package:revali/server/makers/creators/create_data_var.dart';
import 'package:revali/server/makers/creators/create_from_json.dart';
import 'package:revali/server/makers/creators/create_header_var.dart';
import 'package:revali/server/makers/creators/create_ip_var.dart';
import 'package:revali/server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali/server/makers/creators/create_param_var.dart';
import 'package:revali/server/makers/creators/create_pipe.dart';
import 'package:revali/server/makers/creators/create_promoted_arg_value.dart';
import 'package:revali/server/makers/creators/create_quer_var.dart';
import 'package:revali/server/makers/creators/get_raw_type.dart';
import 'package:revali/server/makers/utils/byte_stream_body_param.dart';
import 'package:revali/server/makers/utils/create_switch_pattern.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_router/revali_router.dart';

Expression createArgForParam(
  BaseParameterAnnotation annotation,
  ServerParam param, {
  String routePath = '',
}) {
  if (isByteStreamBodyParam(param) && annotation.type == AnnotationType.body) {
    if (byteStreamBodyHasAccess(annotation)) {
      throw ArgumentError(
        '@Body access is not supported for Stream<List<int>> parameters',
      );
    }

    final stream = createOriginalPayloadStreamVar();

    if (annotation case HasPipe(:final pipe?)) {
      return createPipe(
        pipe,
        param: param,
        annotation: annotation,
        access: stream,
      );
    }

    return stream;
  }

  var variable = switch (annotation.type) {
    AnnotationType.body => createBodyVar(annotation),
    AnnotationType.query ||
    AnnotationType.queryAll => createQueryVar(annotation, param),
    AnnotationType.cookie => createCookieVar(annotation, param),
    AnnotationType.param => createParamVar(
      annotation,
      param,
      routePath: routePath,
    ),
    AnnotationType.header ||
    AnnotationType.headerAll => createHeaderVar(annotation, param),
    AnnotationType.ip => createIpVar(),
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
    true => param.type.nonNullName,
    false => getRawType(param.type).replaceAll('?', ''),
  };

  // Coerced query/header multi-values are `List<dynamic>` / `Set<dynamic>`.
  // JSON bodies decode sets as `List`. A pattern of `List<String>` / `Set`
  // never matches those at runtime, so match the unspecialized iterable and
  // let [createPromotedArgValue] cast / toSet elements.
  final patternType = switch (rawType) {
    final type when type.startsWith('List') => 'List',
    // JSON has no Set; decoded arrays are List. Iterable matches both.
    final type when type.startsWith('Set') => 'Iterable',
    final type when type.startsWith('Iterable') => 'Iterable',
    _ => rawType,
  };

  return createSwitchPattern(variable, {
    Block.of([
      declareFinal('data', type: refer(patternType)).code,
      if (rawType.startsWith('Map')) ...[
        const Code('when'),
        refer('data').property('isNotEmpty').code,
      ],
    ]): createPromotedArgValue(
      paramType: param.type,
      fromJson: fromJson,
    ),
    // Query/header values are coerced (e.g. "5" → 5, "true" → true). When the
    // parameter type is String, accept those primitives and stringify them
    // instead of throwing MissingArgumentException. Do not match arbitrary
    // Object (e.g. empty JSON Map `{}`) — that should fall through to the
    // default / missing-argument arms.
    if (rawType == 'String') ...{
      Block.of([declareFinal('data', type: refer('num')).code]): refer(
        'data',
      ).property('toString').call([]),
      Block.of([declareFinal('data', type: refer('bool')).code]): refer(
        'data',
      ).property('toString').call([]),
    },
    // Coerced ints should satisfy double parameters (`?n=5` → 5).
    if (rawType == 'double')
      Block.of([declareFinal('data', type: refer('num')).code]): refer(
        'data',
      ).property('toDouble').call([]),
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
      Block.of([
        declareFinal('mismatched', type: refer('Object?')).code,
      ]): createMissingArgumentException(
        key: annotation.name ?? param.name,
        location: annotation.type.location,
        expectedType: param.type.nonNullName,
        actualType: actualTypeOf(refer('mismatched')),
      ).thrown,
    },
  });
}
