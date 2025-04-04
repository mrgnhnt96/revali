// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createPipe(
  ServerPipe pipe, {
  required Expression annotationArgument,
  required String nameOfParameter,
  required String? defaultArgument,
  required AnnotationType type,
  required Expression access,
}) {
  final pipeClass = createClass(pipe.pipe);

  final context = refer((PipeContextImpl).name).newInstanceNamed(
    'from',
    [
      refer('context'),
    ],
    {
      'annotationArgument': annotationArgument,
      'nameOfParameter': literalString(nameOfParameter),
      'type': refer('$type'),
    },
  );

  Expression transform(Expression access) {
    return pipeClass.property('transform').call([
      createSwitchPattern(access, {
        declareFinal('value', type: refer(pipe.convertFrom.name)):
            refer('value'),
        declareFinal('value'):
            refer((ArgumentError).name).newInstanceNamed('value', [
          refer('value'),
          literalString('Unexpected type (${pipe.pipe.className})'),
          literalString(
            'Expected a ${pipe.convertFrom.name} got a '
            r'${value.runtimeType}',
          ),
        ]).thrown,
      }),
      context,
    ]).awaited;
  }

  if (defaultArgument == null || pipe.convertFrom.isNullable) {
    return transform(access);
  }

  return createSwitchPattern(access, {
    literalNull: CodeExpression(Code(defaultArgument)),
    declareFinal('arg'): transform(refer('arg')),
  });
}
