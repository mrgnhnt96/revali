// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String exceptionContent(
  ServerLifecycleComponent component,
  ComponentMethod method,
  String Function(Spec) formatter,
) {
  final (:named, :positioned) = getParams(
    component.params,
    defaultExpression: createGetFromDi(),
  );

  final exceptionType = method.exceptionType ?? (Exception).name;

  final methodParams = getParams(
    method.parameters,
    inferredParams: {
      exceptionType: refer('exception'),
      (ExceptionCatcherContext).name: refer('context'),
      (ExceptionCatcherMeta).name: refer('context.meta'),
      (RouteEntry).name: refer('context.meta.route'),
    },
  );

  final serverClass = component.exceptionClassFor(method);

  final clazz = Class(
    (p) => p
      ..name = serverClass.className
      ..modifier = ClassModifier.final$
      ..extend = refer('${(ExceptionCatcher).name}<$exceptionType>')
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
            ..name = 'catchException'
            ..returns =
                refer('${(ExceptionCatcherResult).name}<$exceptionType>')
            ..annotations.add(refer('override'))
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'exception'
                  ..type = refer(exceptionType),
              ),
              Parameter(
                (p) => p
                  ..name = 'context'
                  ..type = refer((ExceptionCatcherContext).name),
              ),
            ])
            ..body = Block.of(
              [
                declareFinal('component')
                    .assign(
                      refer(component.name).newInstance(positioned, named),
                    )
                    .statement,
                const Code('\n'),
                refer('component')
                    .property(method.name)
                    .call(methodParams.positioned, methodParams.named)
                    .returned
                    .statement,
              ],
            ),
        ),
      ),
  );

  return formatter(clazz);
}
