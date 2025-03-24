import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';

Expression createArgFromHeader(
  ServerHeaderAnnotation annotation,
  ServerParam param,
) {
  var headersRef = refer('context').property('request').property('headers');

  if (annotation.all) {
    headersRef = headersRef.property('getAll');
  } else {
    headersRef = headersRef.property('get');
  }

  var headerValue =
      headersRef.call([literalString(annotation.name ?? param.name)]);

  if (annotation.all) {
    headerValue = switch (param.type) {
      final type when type.name.startsWith('Iterable') => headerValue,
      final type when type.name.startsWith('Set') =>
        headerValue.nullSafeProperty('toSet').call([]),
      _ => headerValue = headerValue.nullSafeProperty('toList').call([])
    };
  }

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!param.type.isNullable && annotation.pipe == null)) {
    headerValue = headerValue.ifNullThen(
      createMissingArgumentException(
        key: annotation.name ?? param.name,
        location: '@${AnnotationType.header.name}',
      ).thrown.parenthesized,
    );
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: annotation.all ? AnnotationType.headerAll : AnnotationType.header,
      access: headerValue,
    );
  } else if (param.type.hasFromJsonConstructor) {
    return createFromJsonArg(
      param.type,
      access: headerValue,
    );
  }

  return headerValue;
}
