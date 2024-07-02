import 'package:analyzer/dart/constant/value.dart';
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
    if (_checkForQueryParam(param) case final result
        when result.getter != null) {
      final (:getter!, :pipe) = result;

      final getterStatement = declareFinal(param.name).assign(getter).statement;
      getters.add(getterStatement);

      if (!param.nullable || param.isRequired) {
        final condition = refer(param.name).equalTo(literalNull);
        final block = Block.of([
          // TODO(mrgnhnt): Add support for custom error messages/exceptions
          refer('Response')
              .newInstanceNamed('badRequest', [], {
                'body': refer('jsonEncode').call([
                  literalMap({
                    'error':
                        literalString('${param.name} is required in query'),
                  })
                ]),
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
        params.named[param.name] = pipe ?? refer(param.name);
      } else {
        params.positional.add(pipe ?? refer(param.name));
      }
      continue;
    }

    if (_checkForParamParam(param) case final result
        when result.getter != null) {
      final (:getter!, :pipe) = result;

      final getterStatement = declareFinal(param.name).assign(getter).statement;
      getters.add(getterStatement);

      if (param.isNamed) {
        params.named[param.name] = pipe ?? refer(param.name);
      } else {
        params.positional.add(pipe ?? refer(param.name));
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

({Expression? getter, Expression? pipe}) _checkForQueryParam(MetaParam param) {
  final queryObjects = param.annotationsFor(
    className: a.Query,
    package: 'revali_annotations',
  );

  if (queryObjects.isEmpty) {
    return (getter: null, pipe: null);
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

  var getter = refer('context')
      .property('url')
      .property('queryParameters')
      .index(literalString(paramName));

  return _checkForPipe(
    queryObject,
    getter: getter,
    name: paramName,
    type: a.ParamType.query,
  );
}

({Expression getter, Expression? pipe}) _checkForPipe(
  DartObject object, {
  required Expression getter,
  required String name,
  required a.ParamType type,
}) {
  var pipe = object.getField('pipe')?.toTypeValue();
  if (pipe == null) {
    return (getter: getter, pipe: null);
  }

  final pipeExpression = createPipe(
    pipe,
    type: type,
    name: name,
  );

  return (getter: getter, pipe: pipeExpression);
}

({Expression? getter, Expression? pipe}) _checkForParamParam(MetaParam param) {
  final paramObjects = param.annotationsFor(
    className: a.Param,
    package: 'revali_annotations',
  );

  if (paramObjects.isEmpty) {
    return (getter: null, pipe: null);
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

  var getter =
      refer('context').property('params').index(literalString(paramName));

  if (!param.nullable) {
    getter = getter.nullChecked;
  }

  return _checkForPipe(
    paramObject,
    getter: getter,
    name: paramName,
    type: a.ParamType.param,
  );
}

Expression createPipe(
  DartType? pipe, {
  required a.ParamType type,
  required String name,
}) {
  if (pipe is! InterfaceType) {
    throw Exception(
      'Invalid pipe type for parameter $name, '
      'expected InterfaceType, got ${pipe.runtimeType}',
    );
  }

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
    refer(name).asA(refer(typeArgs[0])),
    refer('ArgumentMetadata').newInstance([
      refer('$type'),
      literalString(name),
    ]),
  ]);

  return transform;
}
