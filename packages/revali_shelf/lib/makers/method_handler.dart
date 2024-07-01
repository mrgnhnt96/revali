import 'package:code_builder/code_builder.dart';
import 'package:revali_annotations/revali_annotations.dart' as a;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/makers/utils/meta_method_extensions.dart';

Spec methodHandler(MetaMethod method, MetaRoute route) {
  final getters = <Code>[];
  final checks = <Code>[];
  final params = (positional: <Expression>[], named: <String, Expression>{});

  for (final param in method.params) {
    final queryParam = _checkForQueryParam(param);
    if (queryParam != null) {
      final getter = declareFinal(param.name).assign(queryParam).statement;
      getters.add(getter);

      if (!param.nullable) {
        final condition = refer(param.name).equalTo(literalNull);
        final block = Block.of([
          // TODO(mrgnhnt): Add support for custom error messages/exceptions
          refer('Response')
              .newInstanceNamed('badRequest', [], {
                'body': literalMap({
                  'error': literalString('${param.name} is required in query'),
                }),
              })
              .returned
              .statement,
        ]);

        final ifCheck = Block.of([
          Code('if ('),
          condition.code,
          Code(') {'),
          block,
          Code('}'),
        ]);

        checks.add(ifCheck);
      }

      if (param.isNamed) {
        params.named[param.name] = refer(param.name);
      } else {
        params.positional.add(refer(param.name));
      }
      continue;
    }

    final paramParam = _checkForParamParam(param);
    if (paramParam != null) {
      final getter = declareFinal(param.name).assign(paramParam).statement;
      getters.add(getter);

      if (param.isNamed) {
        params.named[param.name] = refer(param.name);
      } else {
        params.positional.add(refer(param.name));
      }
      continue;
    }

    if (param.isRequired) {
      throw Exception(
        'Failed to retrieve required parameter ${param.name}, '
        'did you forget to add a @Query or @Param annotation?',
      );
    }

    // TODO(MRGNHNT): Add support for other types of parameters
  }

  return Method(
    (b) => b
      ..name = method.handlerName(route)
      ..returns = refer('Handler')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'controller'
            ..type = refer(route.className),
        ),
      )
      ..body = Block.of([
        refer('Pipeline')
            .newInstance([])
            .property('addHandler')
            .call([
              Method(
                (b) => b
                  ..requiredParameters.add(
                    Parameter(
                      (b) => b..name = 'context',
                    ),
                  )
                  ..body = Block.of([
                    ...getters,
                    ...checks,
                    refer('controller')
                        .property(method.name)
                        .call(params.positional, params.named)
                        .statement,
                    refer('Response')
                        .newInstanceNamed('ok', [literalString(method.name)])
                        .returned
                        .statement,
                  ]),
              ).closure,
            ])
            .returned
            .statement,
      ]),
  );
}

Expression? _checkForQueryParam(MetaParam param) {
  final queryObject = param.annotationFor(
    className: '${a.Query}',
    package: 'revali_annotations',
  );

  if (queryObject == null) {
    return null;
  }

  var paramName = queryObject.getField('name')?.toStringValue();

  if (paramName == null) {
    paramName = param.name;
  }

  return refer('context')
      .property('url')
      .property('queryParameters')
      .index(literalString(paramName));
}

Expression? _checkForParamParam(MetaParam param) {
  final queryObject = param.annotationFor(
    className: '${a.Param}',
    package: 'revali_annotations',
  );

  if (queryObject == null) {
    return null;
  }

  var paramName = queryObject.getField('name')?.toStringValue();

  if (paramName == null) {
    paramName = param.name;
  }

  final expression =
      refer('context').property('params').index(literalString(paramName));

  if (!param.nullable) {
    return expression.nullChecked;
  }

  return expression;
}
