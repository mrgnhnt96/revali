import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';

Expression createArgFromHeader(
  ServerHeaderAnnotation annotation,
  ServerParam header,
) {
  var headersRef = refer('context').property('request').property('headers');

  if (annotation.all) {
    headersRef = headersRef.property('getAll');
  } else {
    headersRef = headersRef.property('get');
  }

  var headerValue =
      headersRef.call([literalString(annotation.name ?? header.name)]);

  if (annotation.all) {
    headerValue = switch (header.type) {
      final type when type.startsWith('Iterable') => headerValue,
      final type when type.startsWith('Set') =>
        headerValue.nullSafeProperty('toSet').call([]),
      _ => headerValue = headerValue.nullSafeProperty('toList').call([])
    };
  }

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!header.isNullable && annotation.pipe == null)) {
    headerValue = headerValue.ifNullThen(
      createMissingArgumentException(
        key: annotation.name ?? header.name,
        location: '@${AnnotationType.header.name}',
      ).thrown.parenthesized,
    );
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
