// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/makers/creators/create_constructor_parameters.dart';
import 'package:revali_server/makers/creators/create_fields.dart';
import 'package:revali_server/makers/creators/create_generics.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/utils/for_in_loop.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/if_statement.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String exceptionContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) {
  final methods = component.exceptionCatchers;

  final (:named, :positioned) = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
    useField: true,
  );

  final parameters = createConstructorParameters(component.params);
  final fields = createFields(component.params);
  final generics = createGenerics(component.genericTypes);

  final groupedMethods = groupBy(methods, (e) {
    return e.exceptionType ?? 'void';
  });

  final clazz = Class(
    (p) => p
      ..name = component.exceptionClass.className
      ..modifier = ClassModifier.final$
      ..extend = refer('${(ExceptionCatcher).name}<dynamic>')
      ..constructors.add(
        Constructor(
          (p) => p
            ..constant = true
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'di'
                  ..toThis = true
                  ..named = false,
              ),
            )
            ..optionalParameters.addAll(parameters),
        ),
      )
      ..types.addAll(generics)
      ..fields.add(
        Field(
          (p) => p
            ..type = refer('DI')
            ..name = 'di'
            ..modifier = FieldModifier.final$,
        ),
      )
      ..fields.addAll(fields)
      ..methods.addAll([
        Method(
          (p) => p
            ..name = 'canCatch'
            ..returns = refer('bool')
            ..annotations.add(refer('override'))
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'exception'
                  ..type = refer('Object'),
              ),
            )
            ..body = Block.of([
              for (final exception in methods)
                ifStatement(
                  refer(
                    'exception',
                  ).isA(refer(exception.exceptionType ?? 'void')),
                  body: literalTrue.returned.statement,
                ).code,
              const Code('\n'),
              literalFalse.returned.statement,
            ]),
        ),
        Method(
          (p) => p
            ..name = 'catchException'
            ..returns = refer('${(ExceptionCatcherResult).name}<dynamic>')
            ..annotations.add(refer('override'))
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'exception'
                  ..type = refer('dynamic'),
              ),
              Parameter(
                (p) => p
                  ..name = 'context'
                  ..type = refer((Context).name),
              ),
            ])
            ..body = Block.of([
              declareFinal('component')
                  .assign(refer(component.name).newInstance(positioned, named))
                  .statement,
              const Code('\n'),
              ...[
                for (final MapEntry(:key, value: values)
                    in groupedMethods.entries) ...[
                  ifStatement(
                    refer('exception').isA(refer(key)),
                    body: _createComponentMethods(
                      key,
                      values,
                      inferredParams: {key: refer('exception')},
                    ),
                  ).code,
                  const Code('\n'),
                ],
              ],
              const Code('\n'),
              refer(
                'ExceptionCatcherResult',
              ).constInstanceNamed('unhandled', []).returned.statement,
            ]),
        ),
      ]),
  );

  return formatter(clazz);
}

Code _createComponentMethods(
  String key,
  Iterable<ServerLifecycleComponentMethod> methods, {
  Map<String, Expression> inferredParams = const {},
}) {
  Iterable<Code> getHandlers() sync* {
    for (final method in methods) {
      final params = getParams(
        method.parameters,
        inferredParams: inferredParams,
      );

      final code = Method(
        (p) => p
          ..lambda = true
          ..body = Block.of([
            refer(
              'component',
            ).property(method.name).call(params.positioned, params.named).code,
          ]),
      );

      yield code.closure.code;
    }
  }

  final handlers = getHandlers();

  return Block.of([
    declareFinal('handlers')
        .assign(
          literalList(
            handlers,
            refer('${(ExceptionCatcherResult).name}<$key> Function()'),
          ),
        )
        .statement,
    const Code('\n'),
    forInLoop(
      declaration: declareFinal('handler'),
      iterable: refer('handlers'),
      body: Block.of([
        ifStatement(
          refer('handler').call([]),
          pattern: (
            cse: declareFinal('result'),
            when: refer('result').property('isHandled'),
          ),
          body: refer('result').returned.statement,
        ).code,
      ]),
    ).code,
  ]);
}
