// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/makers/creators/create_constructor_parameters.dart';
import 'package:revali_server/makers/creators/create_fields.dart';
import 'package:revali_server/makers/creators/create_generics.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/utils/create_component_methods.dart';
import 'package:revali_server/makers/utils/for_in_loop.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String interceptorContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) {
  final params = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
    useField: true,
  );

  final parameters = createConstructorParameters(component.params);
  final fields = createFields(component.params);
  final generics = createGenerics(component.genericTypes);

  final clazz = Class(
    (p) => p
      ..name = component.interceptorClass.className
      ..implements.add(refer((Interceptor).name))
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
      ..methods.addAll([_pre(component, params), _post(component, params)]),
  );

  return formatter(clazz);
}

Method _pre(
  ServerLifecycleComponent component,
  ({Iterable<Expression> positioned, Map<String, Expression> named}) params,
) {
  final (:named, :positioned) = params;

  return Method(
    (p) => p
      ..name = 'pre'
      ..returns = refer('Future<void>')
      ..modifier = MethodModifier.async
      ..annotations.add(refer('override'))
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'context'
            ..type = refer((Context).name),
        ),
      )
      ..body = Block.of([
        declareFinal('component')
            .assign(refer(component.name).newInstance(positioned, named))
            .statement,
        const Code('\n'),
        declareFinal('pres')
            .assign(
              literalList([
                ...createComponentMethods(component.interceptors.pre),
              ], refer('FutureOr<void> Function()')),
            )
            .statement,
        const Code('\n'),
        forInLoop(
          declaration: declareFinal('pre'),
          iterable: refer('pres'),
          body: refer('pre').call([]).awaited.statement,
        ).code,
      ]),
  );
}

Method _post(
  ServerLifecycleComponent component,
  ({Iterable<Expression> positioned, Map<String, Expression> named}) params,
) {
  final (:named, :positioned) = params;

  return Method(
    (p) => p
      ..name = 'post'
      ..returns = refer('Future<void>')
      ..modifier = MethodModifier.async
      ..annotations.add(refer('override'))
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'context'
            ..type = refer((Context).name),
        ),
      )
      ..body = Block.of([
        declareFinal('component')
            .assign(refer(component.name).newInstance(positioned, named))
            .statement,
        const Code('\n'),
        declareFinal('posts')
            .assign(
              literalList([
                ...createComponentMethods(component.interceptors.post),
              ], refer('FutureOr<void> Function()')),
            )
            .statement,
        const Code('\n'),
        forInLoop(
          declaration: declareFinal('post'),
          iterable: refer('posts'),
          body: refer('post').call([]).awaited.statement,
        ).code,
      ]),
  );
}
