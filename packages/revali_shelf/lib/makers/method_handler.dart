import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

  Expression methodCall = refer('controller')
      .property(method.name)
      .call(params.positional, params.named);

  var response = refer('Response')
      .newInstanceNamed('ok', [literalString(method.name)])
      .returned
      .statement;

  if (!method.returnType.isVoid) {
    methodCall = declareFinal('result').assign(methodCall);

    response = refer('Response')
        .newInstanceNamed('ok', [
          refer('jsonEncode').call([
            literalMap(
              {
                'data': refer('result'),
              },
            )
          ]),
        ])
        .returned
        .statement;

    if (!method.returnType.isPrimitive) {
      final element = method.returnType.element;
      if (element is ClassElement) {
        final toJson = element.getMethod('toJson');
        if (toJson != null) {
          methodCall = methodCall.property('toJson').call([]);
        }
      }
    }
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
                    methodCall.statement,
                    response,
                  ]),
              ).closure,
            ])
            .returned
            .statement,
      ]),
  );
}

Expression? _checkForQueryParam(MetaParam param) {
  final queryObjects = param.annotationsFor(
    className: a.Query,
    package: 'revali_annotations',
  );

  if (queryObjects.isEmpty) {
    return null;
  }

  if (queryObjects.length > 1) {
    throw Exception(
      'Found multiple @Query annotations on parameter ${param.name}',
    );
  }

  final queryObject = queryObjects.first;

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
  final paramObjects = param.annotationsFor(
    className: a.Param,
    package: 'revali_annotations',
  );

  if (paramObjects.isEmpty) {
    return null;
  }

  if (paramObjects.length > 1) {
    throw Exception(
      'Found multiple @Param annotations on parameter ${param.name}',
    );
  }

  final paramObject = paramObjects.first;

  var paramName = paramObject.getField('name')?.toStringValue();
  if (paramName == null) {
    paramName = param.name;
  }

  var pipe = paramObject.getField('pipe')?.toTypeValue();

  var getter =
      refer('context').property('params').index(literalString(paramName));

  if (!param.nullable) {
    getter = getter.nullChecked;
  }

  if (pipe == null) {
    return getter;
  }

  if (pipe is! InterfaceType) {
    throw Exception(
      'Invalid pipe type for parameter ${param.name}, '
      'expected InterfaceType, got ${pipe.runtimeType}',
    );
  }

  final pipeExpression = createPipe(
    pipe,
    type: a.ParamType.param,
    name: paramName,
    getter: getter,
  );

  return pipeExpression;
}

Expression createPipe(
  InterfaceType pipe, {
  required a.ParamType type,
  required String name,
  required Expression getter,
}) {
  final pipeTransform = pipe.allSupertypes.firstWhere(
      (element) =>
          element.element.name == 'PipeTransform' &&
          element.element.library.identifier.contains('revali_annotations'),
      orElse: () {
    throw Exception(
        'Pipe (${pipe.element.name}) must be of type PipeTransform');
  });

  final params = (named: <String, Expression>{}, positional: <Expression>[]);
  final pipeParams = pipe.element.constructors.first.parameters;
  for (final param in pipeParams) {
    final getter = refer('DI').property('instance').property('get').call([]);

    if (param.isNamed) {
      params.named[param.name] = getter;
    } else {
      params.positional.add(getter);
    }
  }

  final pipeInstance =
      refer(pipe.element.name).newInstance(params.positional, params.named);

  final typeArgs = <String>[
    for (final type in pipeTransform.typeArguments)
      type.getDisplayString(withNullability: true),
  ];

  // call transform method on pipe
  final transform = pipeInstance.property('transform').call([
    getter.asA(refer(typeArgs[0])),
    refer('ArgumentMetadata').newInstance([
      refer('$type'),
      literalString(name),
    ]),
  ]);

  return transform;
}
