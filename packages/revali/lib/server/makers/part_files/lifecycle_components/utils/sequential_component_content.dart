// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_lifecycle_component.dart';
import 'package:revali/server/converters/server_lifecycle_component_method.dart';
import 'package:revali/server/makers/creators/create_constructor_parameters.dart';
import 'package:revali/server/makers/creators/create_fields.dart';
import 'package:revali/server/makers/creators/create_generics.dart';
import 'package:revali/server/makers/creators/create_get_from_di.dart';
import 'package:revali/server/makers/part_files/lifecycle_components/utils/create_component_methods.dart';
import 'package:revali/server/makers/utils/create_switch_pattern.dart';
import 'package:revali/server/makers/utils/for_in_loop.dart';
import 'package:revali/server/makers/utils/get_params.dart';
import 'package:revali/server/makers/utils/if_statement.dart';

/// Builds the class for a lifecycle role that runs a **sequence** of component
/// methods and returns early on the first short-circuiting result.
///
/// Guards and middleware share this shape exactly — they differ only in
/// naming, in which result getter ends the loop, and in the result returned
/// when nothing short-circuits. The remaining roles (interceptor, exception
/// catcher, wrapper) have genuinely different shapes and keep their own
/// makers.
///
/// The generated class looks like:
///
/// ```dart
/// class FooGuard implements Guard {
///   const FooGuard(this.di);
///
///   final DI di;
///
///   @override
///   Future<GuardResult> protect(Context context) async {
///     final component = Foo();
///     final guards = <FutureOr<GuardResult> Function()>[ ... ];
///     for (final guard in guards) {
///       final result = await switch (guard()) { ... };
///       if (result.isBlock) return result;
///     }
///     return const GuardResult.pass();
///   }
/// }
/// ```
String sequentialComponentContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter, {
  required String className,
  required String interfaceName,
  required String resultType,
  required String methodName,
  required List<ServerLifecycleComponentMethod> methods,
  required String listName,
  required String itemName,

  /// Getter on the result that ends the loop early, e.g. `isBlock`.
  required String shortCircuitOn,

  /// Const constructor returned when nothing short-circuits, e.g. `pass`.
  required String fallthrough,
}) {
  final (:positioned, :named) = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
    useField: true,
  );

  final parameters = createConstructorParameters(component.params);
  final fields = createFields(component.params);
  final generics = createGenerics(component.wrapperGenericTypes);

  final clazz = Class(
    (p) => p
      ..name = className
      ..implements.add(refer(interfaceName))
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
      ..methods.add(
        Method(
          (p) => p
            ..name = methodName
            ..returns = refer('Future<$resultType>')
            ..modifier = MethodModifier.async
            ..annotations.add(refer('override'))
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'context'
                  ..type = refer('Context'),
              ),
            )
            ..body = Block.of([
              declareFinal('component')
                  .assign(
                    refer(
                      component.instantiatedName,
                    ).newInstance(positioned, named),
                  )
                  .statement,
              const Code('\n'),
              declareFinal(listName)
                  .assign(
                    literalList([
                      ...createComponentMethods(methods),
                    ], refer('FutureOr<$resultType> Function()')),
                  )
                  .statement,
              const Code('\n'),
              forInLoop(
                declaration: declareFinal(itemName),
                iterable: refer(listName),
                body: Block.of([
                  declareFinal('result')
                      .assign(
                        createSwitchPattern(refer(itemName).call([]), {
                          declareFinal(
                            'future',
                            type: refer('Future<$resultType>'),
                          ): refer(
                            'future',
                          ),
                          declareFinal(
                            'result',
                            type: refer(resultType),
                          ): refer(
                            'Future',
                          ).property('value').call([refer('result')]),
                        }).awaited,
                      )
                      .statement,
                  const Code('\n'),
                  ifStatement(
                    refer('result').property(shortCircuitOn),
                    body: refer('result').returned.statement,
                  ).code,
                ]),
              ).code,
              const Code('\n'),
              declareConst(
                resultType,
              ).property(fallthrough).call([]).returned.statement,
            ]),
        ),
      ),
  );

  return formatter(clazz);
}
