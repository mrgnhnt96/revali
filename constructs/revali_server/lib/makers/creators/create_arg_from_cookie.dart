import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_cookie_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

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

  if (createThrowMissingArgument(annotation, param) case final thrown?) {
    cookieValue = cookieValue.ifNullThen(thrown);
  }

  cookieValue = createDefaultArgument(cookieValue, param) ??
      createFromJson(param.type, cookieValue) ??
      cookieValue;

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: AnnotationType.cookie,
      access: cookieValue,
    );
  }

  return cookieValue;
}
