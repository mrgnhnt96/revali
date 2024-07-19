import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';

Expression createArgFromBody(
  ServerBodyAnnotation annotation,
  ServerParam param,
) {
  var bodyVar = refer('context').property('request').property('body');

  if (annotation.access case final access?) {
    bodyVar = bodyVar.property('data?');
    for (final part in access) {
      bodyVar = bodyVar.index(literalString(part));

      final acceptsNull = annotation.acceptsNull;
      if ((acceptsNull != null && !acceptsNull) ||
          (!param.isNullable && annotation.pipe == null)) {
        bodyVar = bodyVar
            // TODO(MRGNHNT): Throw custom exception here
            .ifNullThen(literalString('Missing value!').thrown.parenthesized);
      }
    }
  } else {
    bodyVar = bodyVar.property('data');
  }

  if (annotation.pipe case final pipe?) {
    final access = annotation.access;
    return createPipeContext(
      pipe,
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

  return bodyVar;
}