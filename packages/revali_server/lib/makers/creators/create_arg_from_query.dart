import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_query_annotation.dart';
import 'package:revali_server/makers/creators/create_pipe_context.dart';

Expression createArgFromQuery(
  ServerQueryAnnotation annotation,
  ServerParam param,
) {
  Expression queryVar = refer('context').property('request');

  if (annotation.all) {
    queryVar = queryVar.property('queryParametersAll');
  } else {
    queryVar = queryVar.property('queryParameters');
  }

  var queryValue = queryVar.index(literalString(annotation.name ?? param.name));

  final acceptsNull = annotation.acceptsNull;
  if ((acceptsNull != null && !acceptsNull) ||
      (!param.isNullable && annotation.pipe == null)) {
    queryValue = queryValue
        // TODO(MRGNHNT): Throw custom exception here
        .ifNullThen(literalString('Missing value!').thrown.parenthesized);
  }

  if (annotation.pipe case final pipe?) {
    final name = annotation.name;
    return createPipeContext(
      pipe,
      annotationArgument: name == null ? literalNull : literalString(name),
      nameOfParameter: param.name,
      type: annotation.all ? AnnotationType.queryAll : AnnotationType.query,
      access: queryValue,
    );
  }

  return queryValue;
}
