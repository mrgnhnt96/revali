import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';

Expression createArgFromHeader(
  ServerHeaderAnnotation annotation,
  ServerParam header,
) {
  final headersRef = refer('context').property('request').property('headers');

  var headerValue =
      headersRef.index(literalString(annotation.name ?? header.name));

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!header.isNullable && annotation.pipe == null)) {
    headerValue = headerValue
        // TODO(MRGNHNT): Throw custom exception here
        .ifNullThen(literalString('Missing value!').thrown.parenthesized);
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipeContext(
      pipe,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: header.name,
      type: AnnotationType.header,
      access: headerValue,
    );
  }

  return headerValue;
}
