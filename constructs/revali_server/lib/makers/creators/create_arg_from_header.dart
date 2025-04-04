import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

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

  if (createThrowMissingArgument(annotation, param) case final thrown?) {
    headerValue = headerValue.ifNullThen(thrown);
  }

  headerValue = createDefaultArgument(headerValue, param) ??
      createFromJson(param.type, headerValue) ??
      headerValue;

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: annotation.type,
      access: headerValue,
    );
  }

  return headerValue;
}
