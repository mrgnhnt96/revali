// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method;
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';
import 'package:revali_server/makers/utils/for_in_loop.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createPipe(
  ServerPipe pipe, {
  required ServerParam param,
  required Expression access,
  required BaseParameterAnnotation annotation,
}) {
  final pipeClass = refer(pipe.clazz.variableName);

  final context = refer((PipeContextImpl).name).newInstance(
    [],
    {
      'data': refer('context').property('data'),
      'meta': refer('context').property('meta'),
      'reflect': refer('context').property('reflect'),
      'request': refer('context').property('request'),
      'response': refer('context').property('response'),
      'route': refer('context').property('route'),
      'annotationArgument': literal(annotation.name),
      'nameOfParameter': literalString(param.name),
      'type': refer((AnnotationType).name).property(annotation.type.name),
    },
  );

  Expression transform(Expression access) {
    Expression piped(Expression access) {
      var piped = pipeClass.property('transform').call([
        createSwitchPattern(access, {
          declareFinal('value', type: refer(pipe.convertFrom.nonNullName)):
              refer('value'),
          if (pipe.convertFrom.isNullable)
            Block.of([
              literalNull.code,
              const Code('||'),
              const Code('Map()'),
              const Code('||'),
              const Code('List()'),
            ]): literalNull,
          declareFinal('value'):
              refer((ArgumentError).name).newInstanceNamed('value', [
            refer('value'),
            literalString('[${pipe.clazz.className}] Unexpected type'),
            literalString(
              'Expected a ${pipe.convertFrom.name} got a '
              r'${value.runtimeType}',
            ),
          ]).thrown,
        }),
        context,
      ]);

      if (param.defaultValue case final defaultArgument?) {
        piped = piped.property('catchError').call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = '_'))
              ..body = Code(defaultArgument),
          ).closure,
        ]);

        if (pipe.convertTo.isNullable) {
          piped = piped.ifNullThen(CodeExpression(Code(defaultArgument)));
        }
      }

      return piped.awaited;
    }

    return switch (param.type.isIterable) {
      true => CodeExpression(
          Block.of([
            const Code('['),
            forInLoop(
              declaration: declareFinal('data'),
              iterable: access.ifNullThen(literalList([])),
              body: piped(refer('data')).code,
              blockBody: false,
            ).code,
            const Code(']'),
          ]),
        ),
      false => piped(access),
    };
  }

  final defaultArgument = param.defaultValue;
  if (defaultArgument == null || pipe.convertFrom.isNullable) {
    return transform(access);
  }

  return createSwitchPattern(access, {
    literalNull: CodeExpression(Code(defaultArgument)),
    declareFinal('arg'): transform(refer('arg')),
  });
}
