import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_impl_content.dart';
import 'package:revali_client_gen/models/client_controller.dart';
import 'package:revali_construct/revali_construct.dart';

PartFile controllerImplFile(
  ClientController controller,
  String Function(Spec) formatter,
) {
  final content = createImplContent(controller);

  return PartFile(
    path: ['lib', 'src', 'impls', controller.implementationName.toSnakeCase()],
    content: formatter(content),
  );
}
