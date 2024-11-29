import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/files/part_file.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/exception_content.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/guard_content.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/interceptor_content.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/middleware_content.dart';

Iterable<PartFile> lifecycleComponentFilesMaker(
  ServerLifecycleComponent component,
  String Function(Spec) formatter,
) sync* {
  List<String> path(String file) => [
        'lifecycle_components',
        component.name.toSnakeCase(),
        file.toNoCase().trim().toSnakeCase(),
      ];

  if (component.hasExceptionCatchers) {
    yield PartFile(
      path: path(component.exceptionClass.className),
      content: exceptionContent(component, formatter),
    );
  }

  if (component.hasGuards) {
    yield PartFile(
      path: path(component.guardClass.className),
      content: guardContent(component, formatter),
    );
  }

  if (component.hasMiddlewares) {
    yield PartFile(
      path: path(component.middlewareClass.className),
      content: middlewareContent(component, formatter),
    );
  }

  if (component.hasInterceptors) {
    yield PartFile(
      path: path(component.interceptorClass.className),
      content: interceptorContent(component, formatter),
    );
  }
}
