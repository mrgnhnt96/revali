import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_cookie_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';

Expression createArgFromCookie(
  ServerCookieAnnotation annotation,
  ServerParam param,
) {
  final cookieVar = refer('context')
      .property('request')
      .property('headers')
      .property('cookies');

  var cookieValue =
      cookieVar.index(literalString(annotation.name ?? param.name));

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!param.type.isNullable && annotation.pipe == null)) {
    cookieValue = cookieValue.ifNullThen(
      createMissingArgumentException(
        key: annotation.name ?? param.name,
        location: '@${AnnotationType.cookie.name}',
      ).thrown.parenthesized,
    );
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: AnnotationType.cookie,
      access: cookieValue,
    );
  } else if (param.type.hasFromJsonConstructor) {
    return createFromJsonArg(
      param.type,
      access: cookieValue,
    );
  }

  return cookieValue;
}
