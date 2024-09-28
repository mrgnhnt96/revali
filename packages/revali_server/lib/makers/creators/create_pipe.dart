// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createPipe(
  ServerPipe pipe, {
  required Expression annotationArgument,
  required String nameOfParameter,
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

  return pipeClass.property('transform').call([access, context]).awaited;
}
