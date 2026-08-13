import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_lifecycle_component.dart';
import 'package:revali/server/makers/part_files/lifecycle_components/utils/sequential_component_content.dart';
import 'package:revali/server/makers/utils/type_extensions.dart';
import 'package:revali_core/revali_core.dart';

String middlewareContent(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) {
  return sequentialComponentContent(
    component,
    formatter,
    className: component.middlewareClass.className,
    interfaceName: (Middleware).name,
    resultType: (MiddlewareResult).name,
    methodName: 'use',
    methods: component.middlewares,
    listName: 'middlewares',
    itemName: 'middleware',
    shortCircuitOn: 'isStop',
    fallthrough: 'next',
  );
}
