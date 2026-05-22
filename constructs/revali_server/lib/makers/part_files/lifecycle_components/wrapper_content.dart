// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/makers/creators/create_constructor_parameters.dart';
import 'package:revali_server/makers/creators/create_fields.dart';
import 'package:revali_server/makers/creators/create_generics.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String wrapperContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) {
  final (:positioned, :named) = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
    useField: true,
  );

  final parameters = createConstructorParameters(component.params);
  final fields = createFields(component.params);
  final generics = createGenerics(component.wrapperGenericTypes);

  Map<String, Expression> nextInferredParams(Expression next) {
    return {
      ServerLifecycleComponentMethod.nextResponse: next,
      'Future<Response> Function()': next,
    };
  }

  Expression createWrapperCall(
    ServerLifecycleComponentMethod method,
    Expression next,
  ) {
    final (:positioned, :named) = getParams(
      method.parameters,
      inferredParams: nextInferredParams(next),
    );

    return refer('component').property(method.name).call(positioned, named);
  }

  Expression buildWrapperChain(List<ServerLifecycleComponentMethod> methods) {
    if (methods.isEmpty) {
      return refer('next').call([]);
    }

    Expression nextArg = refer('next');
    for (final method in methods.reversed.skip(1)) {
      final inner = nextArg;
      nextArg = Method(
        (b) => b
          ..lambda = true
          ..body = createWrapperCall(method, inner).code,
      ).closure;
    }

    return createWrapperCall(methods.first, nextArg);
  }

  final wrapperCall = buildWrapperChain(component.requestWrappers);

  final clazz = Class(
    (p) => p
      ..name = component.requestWrapperClass.className
      ..implements.add(refer((RequestWrapper).name))
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
            ..name = 'wrap'
            ..returns = refer(ServerLifecycleComponentMethod.wrapperResult)
            ..annotations.add(refer('override'))
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'context'
                  ..type = refer((Context).name),
              ),
              Parameter(
                (p) => p
                  ..name = 'next'
                  ..type = refer(ServerLifecycleComponentMethod.nextResponse),
              ),
            ])
            ..body = Block.of([
              declareFinal('component')
                  .assign(
                    refer(
                      component.instantiatedName,
                    ).newInstance(positioned, named),
                  )
                  .statement,
              const Code('\n'),
              wrapperCall.returned.statement,
            ]),
        ),
      ),
  );

  return formatter(clazz);
}
