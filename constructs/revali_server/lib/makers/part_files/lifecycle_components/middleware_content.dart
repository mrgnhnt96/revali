// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/utils/create_component_methods.dart';
import 'package:revali_server/makers/utils/for_in_loop.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/if_statement.dart';
import 'package:revali_server/makers/utils/switch_statement.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String middlewareContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) {
  final (:positioned, :named) = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
  );

  final clazz = Class(
    (p) => p
      ..name = component.middlewareClass.className
      ..implements.add(refer((Middleware).name))
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
            ),
        ),
      )
      ..fields.add(
        Field(
          (p) => p
            ..type = refer('DI')
            ..name = 'di'
            ..modifier = FieldModifier.final$,
        ),
      )
      ..methods.add(
        Method(
          (p) => p
            ..name = 'use'
            ..returns = refer('Future<${(MiddlewareResult).name}>')
            ..modifier = MethodModifier.async
            ..annotations.add(refer('override'))
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'context'
                  ..type = refer((MiddlewareContext).name),
              ),
            )
            ..body = Block.of(
              [
                declareFinal('component')
                    .assign(
                      refer(component.name).newInstance(positioned, named),
                    )
                    .statement,
                const Code('\n'),
                declareFinal('middlewares')
                    .assign(
                      literalList(
                        [
                          ...createComponentMethods(
                            component.middlewares,
                            inferredParams: {
                              (MiddlewareContext).name: refer('context'),
                            },
                          ),
                        ],
                        refer(
                          'FutureOr<${(MiddlewareResult).name}> Function()',
                        ),
                      ),
                    )
                    .statement,
                const Code('\n'),
                forInLoop(
                  declaration: declareFinal('middleware'),
                  iterable: refer('middlewares'),
                  body: Block.of([
                    declareFinal('result')
                        .assign(
                          switchPatternStatement(
                            refer('middleware').call([]),
                            cases: [
                              (
                                declareFinal(
                                  'future',
                                  type: refer(
                                    'Future<${(MiddlewareResult).name}>',
                                  ),
                                ).code,
                                refer('future').code,
                              ),
                              (
                                declareFinal(
                                  'result',
                                  type: refer((MiddlewareResult).name),
                                ).code,
                                refer('Future')
                                    .property('value')
                                    .call([refer('result')]).code,
                              ),
                            ],
                          ).awaited,
                        )
                        .statement,
                    const Code('\n'),
                    ifStatement(
                      refer('result').property('isStop'),
                      body: refer('result').returned.statement,
                    ).code,
                  ]),
                ).code,
                const Code('\n'),
                declareConst((MiddlewareResult).name)
                    .property('next')
                    .call([])
                    .returned
                    .statement,
              ],
            ),
        ),
      ),
  );

  return formatter(clazz);
}