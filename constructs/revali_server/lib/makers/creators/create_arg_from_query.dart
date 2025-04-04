import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_query_annotation.dart';
import 'package:revali_server/makers/creators/create_from_json_arg.dart';
import 'package:revali_server/makers/creators/create_pipe.dart';
import 'package:revali_server/makers/utils/create_default_argument.dart';
import 'package:revali_server/makers/utils/create_throw_missing_argument.dart';

Expression createArgFromQuery(
  ServerQueryAnnotation annotation,
  ServerParam param,
) {
  var queryVar = refer('context').property('request');

  if (annotation.all) {
    queryVar = queryVar.property('queryParametersAll');
  } else {
    queryVar = queryVar.property('queryParameters');
  }

  var queryValue = queryVar.index(literalString(annotation.name ?? param.name));

  if (annotation.all) {
    queryValue = switch (param.type) {
      final type when type.name.startsWith('Iterable') => queryValue,
      final type when type.name.startsWith('Set') =>
        queryValue.nullSafeProperty('toSet').call([]),
      _ => queryValue = queryValue.nullSafeProperty('toList').call([])
    };
  }

  if (createThrowMissingArgument(annotation, param) case final thrown?) {
    queryValue = queryValue.ifNullThen(thrown);
  }

  queryValue = createDefaultArgument(queryValue, param);

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipe(
      pipe,
      defaultArgument: param.defaultValue,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: annotation.type,
      access: queryValue,
    );
  } else if (param.type.hasFromJson) {
    return createFromJsonArg(
      param.type,
      access: queryValue,
    );
  }

  return queryValue;
}
